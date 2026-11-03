namespace EscapeHub.Application.Interfaces;

public interface IFileStorageService
{
    Task SaveAsync(string key, Stream content, CancellationToken cancellationToken = default);
    Stream? OpenRead(string key);
    void Delete(string key);
}
