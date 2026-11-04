using EscapeHub.Domain.Enums;

namespace EscapeHub.Domain.Entities;

public class Payment : BaseEntity
{
    public int BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public string CheckoutId { get; set; } = string.Empty;
    public string CheckoutUrl { get; set; } = string.Empty;
    public PaymentStatus Status { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public string? OrderId { get; set; }
    public DateTime? PaidAt { get; set; }
}
