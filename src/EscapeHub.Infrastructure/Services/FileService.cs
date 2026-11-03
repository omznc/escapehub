using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Files;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class FileService
{
    public const long MaxFileSize = 5 * 1024 * 1024;
    private const string UrlPrefix = "/api/files/";
    private const string RoomsFolder = "rooms";
    private const string ProfilesFolder = "profiles";

    private static readonly Dictionary<string, string> Extensions = new()
    {
        ["image/jpeg"] = ".jpg",
        ["image/png"] = ".png",
        ["image/webp"] = ".webp"
    };

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly IFileStorageService _storage;
    private readonly ILogger<FileService> _logger;

    public FileService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, IFileStorageService storage, ILogger<FileService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _storage = storage;
        _logger = logger;
    }

    public async Task<UploadResponse> UploadProfilePictureAsync(Stream content, string contentType, long length)
    {
        var user = await _db.Users.FirstAsync(u => u.Id == _currentUser.Id);
        var folder = $"{ProfilesFolder}/{user.Id}";
        var url = await SaveImageAsync(folder, content, contentType, length);
        var oldUrl = user.ProfilePictureUrl;
        user.ProfilePictureUrl = url;
        await _db.SaveChangesAsync();
        DeleteStored(oldUrl, folder);
        return new UploadResponse(url);
    }

    public async Task RemoveProfilePictureAsync()
    {
        var user = await _db.Users.FirstAsync(u => u.Id == _currentUser.Id);
        var oldUrl = user.ProfilePictureUrl;
        user.ProfilePictureUrl = null;
        await _db.SaveChangesAsync();
        DeleteStored(oldUrl, $"{ProfilesFolder}/{user.Id}");
    }

    public async Task<UploadResponse> UploadRoomImageAsync(int roomId, Stream content, string contentType, long length)
    {
        var room = await _access.GetManagedRoomAsync(roomId);
        var folder = $"{RoomsFolder}/{room.Id}";
        var url = await SaveImageAsync(folder, content, contentType, length);
        var oldUrl = room.ImageUrl;
        room.ImageUrl = url;
        await _db.SaveChangesAsync();
        DeleteStored(oldUrl, folder);
        return new UploadResponse(url);
    }

    public async Task RemoveRoomImageAsync(int roomId)
    {
        var room = await _access.GetManagedRoomAsync(roomId);
        var oldUrl = room.ImageUrl;
        room.ImageUrl = null;
        await _db.SaveChangesAsync();
        DeleteStored(oldUrl, $"{RoomsFolder}/{room.Id}");
    }

    public StoredFileContent Open(string key)
    {
        EnsureCanRead(key);
        var extension = Path.GetExtension(key).ToLowerInvariant();
        var contentType = Extensions.FirstOrDefault(e => e.Value == extension).Key;
        var stream = contentType == null ? null : _storage.OpenRead(key);
        if (stream == null)
            throw new NotFoundException("File not found.");
        return new StoredFileContent(stream, contentType!);
    }

    private void EnsureCanRead(string key)
    {
        var parts = key.Split('/');
        if (parts.Length != 3 || parts.Any(p => p.Length == 0 || p == ".."))
            throw new NotFoundException("File not found.");
        if (parts[0] == RoomsFolder) return;
        if (parts[0] != ProfilesFolder)
            throw new NotFoundException("File not found.");
        if (_currentUser.IsClient && parts[1] != _currentUser.Id.ToString())
            throw new ForbiddenException("You can open only your own profile picture.");
    }

    private async Task<string> SaveImageAsync(string folder, Stream content, string contentType, long length)
    {
        if (length is 0 or > MaxFileSize)
            throw new BusinessException($"The file must have a size between 1 byte and {MaxFileSize / 1024 / 1024} MB.", "file");
        if (!Extensions.TryGetValue(contentType.ToLowerInvariant(), out var extension))
            throw new BusinessException("Only JPEG, PNG and WebP images are allowed.", "file");

        using var buffer = new MemoryStream();
        await content.CopyToAsync(buffer);
        if (DetectType(buffer.GetBuffer().AsSpan(0, (int)buffer.Length)) != contentType.ToLowerInvariant())
            throw new BusinessException("The file content does not match the image type.", "file");

        var key = $"{folder}/{Guid.NewGuid():N}{extension}";
        buffer.Position = 0;
        await _storage.SaveAsync(key, buffer);
        _logger.LogInformation("Stored file {Key} for user {UserId}", key, _currentUser.Id);
        return UrlPrefix + key;
    }

    private static string? DetectType(ReadOnlySpan<byte> data)
    {
        if (data.StartsWith(new byte[] { 0xFF, 0xD8, 0xFF })) return "image/jpeg";
        if (data.StartsWith(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A })) return "image/png";
        if (data.Length >= 12 && data[..4].SequenceEqual("RIFF"u8) && data[8..12].SequenceEqual("WEBP"u8)) return "image/webp";
        return null;
    }

    private void DeleteStored(string? url, string folder)
    {
        var prefix = $"{UrlPrefix}{folder}/";
        if (url != null && url.StartsWith(prefix, StringComparison.Ordinal))
            _storage.Delete(url[UrlPrefix.Length..]);
    }
}
