using EscapeHub.Domain.Enums;

namespace EscapeHub.Domain.Entities;

public class Notification : BaseEntity
{
    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public bool IsRead { get; set; }
}
