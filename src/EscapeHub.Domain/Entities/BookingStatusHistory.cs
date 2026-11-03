namespace EscapeHub.Domain.Entities;

public class BookingStatusHistory : BaseEntity
{
    public int BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public int? FromStatusId { get; set; }
    public BookingStatus? FromStatus { get; set; }

    public int ToStatusId { get; set; }
    public BookingStatus ToStatus { get; set; } = null!;

    public int? ChangedById { get; set; }
    public ApplicationUser? ChangedBy { get; set; }

    public string? Reason { get; set; }
}
