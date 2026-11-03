namespace EscapeHub.Application.DTOs.Common;

public record MessageResponse(string Message);

public record CountResponse(int Count);

public class ErrorResponse
{
    public string Message { get; set; } = string.Empty;
    public Dictionary<string, string[]> Errors { get; set; } = new();

    public static ErrorResponse From(string message) => new() { Message = message };
}
