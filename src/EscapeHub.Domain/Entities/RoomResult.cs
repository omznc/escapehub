namespace EscapeHub.Domain.Entities;

public class RoomResult : BaseEntity
{
    public int BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public bool Escaped { get; set; }
    public int? CompletionTimeMinutes { get; set; }
    public int? HintsUsed { get; set; }
    public string? ManagerNotes { get; set; }
    public int? Score { get; set; }

    public int RecordedById { get; set; }
    public ApplicationUser RecordedBy { get; set; } = null!;
}
