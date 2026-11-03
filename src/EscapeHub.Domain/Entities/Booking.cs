namespace EscapeHub.Domain.Entities;

public class Booking : BaseEntity
{
    public int ScheduleId { get; set; }
    public Schedule Schedule { get; set; } = null!;

    public int ClientId { get; set; }
    public ApplicationUser Client { get; set; } = null!;

    public int BookingStatusId { get; set; }
    public BookingStatus BookingStatus { get; set; } = null!;

    public int PlayerCount { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal DiscountApplied { get; set; }

    public int? PromotionId { get; set; }
    public Promotion? Promotion { get; set; }

    public string? Notes { get; set; }
    public DateTime? ReminderSentAt { get; set; }

    public RewardRedemption? RewardRedemption { get; set; }
    public ICollection<BookingMember> BookingMembers { get; set; } = new List<BookingMember>();
    public ICollection<BookingStatusHistory> StatusHistory { get; set; } = new List<BookingStatusHistory>();
    public RoomResult? RoomResult { get; set; }
    public ICollection<LoyaltyTransaction> LoyaltyTransactions { get; set; } = new List<LoyaltyTransaction>();
}
