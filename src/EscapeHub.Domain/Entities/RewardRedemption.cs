namespace EscapeHub.Domain.Entities;

public class RewardRedemption : BaseEntity
{
    public int ClientId { get; set; }
    public ApplicationUser Client { get; set; } = null!;

    public int LoyaltyRewardId { get; set; }
    public LoyaltyReward LoyaltyReward { get; set; } = null!;

    public int PointsSpent { get; set; }
    public decimal Value { get; set; }
    public bool IsPercentage { get; set; }
    public string Code { get; set; } = string.Empty;
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }

    public int? BookingId { get; set; }
    public Booking? Booking { get; set; }
}
