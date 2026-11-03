namespace EscapeHub.Domain.Entities;

public class LoyaltyReward : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int PointsCost { get; set; }

    public int RewardTypeId { get; set; }
    public RewardType RewardType { get; set; } = null!;

    public decimal Value { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }

    public ICollection<RewardRedemption> RewardRedemptions { get; set; } = new List<RewardRedemption>();
}
