using EscapeHub.Domain.Enums;

namespace EscapeHub.Domain.Entities;

public class LoyaltyTransaction : BaseEntity
{
    public int ClientId { get; set; }
    public ApplicationUser Client { get; set; } = null!;

    public int Points { get; set; }
    public TransactionType TransactionType { get; set; }

    public int? BookingId { get; set; }
    public Booking? Booking { get; set; }

    public int? RewardRedemptionId { get; set; }
    public RewardRedemption? RewardRedemption { get; set; }

    public string? Description { get; set; }
}
