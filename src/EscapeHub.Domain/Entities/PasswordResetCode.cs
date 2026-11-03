namespace EscapeHub.Domain.Entities;

public class PasswordResetCode : BaseEntity
{
    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public string CodeHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public int FailedAttempts { get; set; }
}
