using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Notifications;

public class NotificationDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class NotificationQuery : PaginationQuery
{
    public bool? UnreadOnly { get; set; }
}
