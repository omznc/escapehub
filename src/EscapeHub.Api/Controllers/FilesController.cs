using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Files;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/files")]
[Authorize]
public class FilesController : ControllerBase
{
    private const long RequestLimit = FileService.MaxFileSize + 64 * 1024;
    private readonly FileService _files;

    public FilesController(FileService files) => _files = files;

    [HttpGet("{**key}")]
    public IActionResult Download(string key)
    {
        var file = _files.Open(key);
        return File(file.Content, file.ContentType);
    }

    [HttpPost("profile-picture")]
    [RequestSizeLimit(RequestLimit)]
    public async Task<UploadResponse> UploadProfilePicture(IFormFile file)
    {
        await using var stream = file.OpenReadStream();
        return await _files.UploadProfilePictureAsync(stream, file.ContentType, file.Length);
    }

    [HttpDelete("profile-picture")]
    public async Task<IActionResult> RemoveProfilePicture()
    {
        await _files.RemoveProfilePictureAsync();
        return NoContent();
    }

    [HttpPost("rooms/{roomId:int}")]
    [Authorize(Roles = Roles.Staff)]
    [RequestSizeLimit(RequestLimit)]
    public async Task<UploadResponse> UploadRoomImage(int roomId, IFormFile file)
    {
        await using var stream = file.OpenReadStream();
        return await _files.UploadRoomImageAsync(roomId, stream, file.ContentType, file.Length);
    }

    [HttpDelete("rooms/{roomId:int}")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> RemoveRoomImage(int roomId)
    {
        await _files.RemoveRoomImageAsync(roomId);
        return NoContent();
    }
}
