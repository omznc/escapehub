namespace EscapeHub.Domain.Entities;

public class BookingMember : BaseEntity
{
    public int BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public string ParticipantName { get; set; } = string.Empty;
}
