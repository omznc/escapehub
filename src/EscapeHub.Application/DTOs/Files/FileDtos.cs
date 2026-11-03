namespace EscapeHub.Application.DTOs.Files;

public record UploadResponse(string Url);

public record StoredFileContent(Stream Content, string ContentType);
