using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Infrastructure.Storage;

public class LocalFileStorage : IFileStorageService
{
    private readonly string _root;

    public LocalFileStorage(FileStorageOptions options)
    {
        _root = options.RootPath;
        Directory.CreateDirectory(_root);
    }

    public async Task SaveAsync(string key, Stream content, CancellationToken cancellationToken = default)
    {
        var path = Resolve(key);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        await using var file = File.Create(path);
        await content.CopyToAsync(file, cancellationToken);
    }

    public Stream? OpenRead(string key)
    {
        var path = Resolve(key);
        return File.Exists(path) ? File.OpenRead(path) : null;
    }

    public void Delete(string key)
    {
        var path = Resolve(key);
        if (File.Exists(path))
            File.Delete(path);
    }

    private string Resolve(string key)
    {
        var path = Path.GetFullPath(Path.Combine(_root, key));
        if (!path.StartsWith(_root + Path.DirectorySeparatorChar, StringComparison.Ordinal))
            throw new ArgumentException("Invalid file key.", nameof(key));
        return path;
    }
}
