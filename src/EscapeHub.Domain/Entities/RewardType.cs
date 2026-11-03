namespace EscapeHub.Domain.Entities;

public class RewardType : ReferenceEntity
{
    public bool IsPercentage { get; set; }

    public ICollection<LoyaltyReward> LoyaltyRewards { get; set; } = new List<LoyaltyReward>();
}
