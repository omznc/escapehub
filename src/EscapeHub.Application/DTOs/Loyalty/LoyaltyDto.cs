using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Loyalty;

public class LoyaltyRewardDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int PointsCost { get; set; }
    public int RewardTypeId { get; set; }
    public string RewardTypeName { get; set; } = string.Empty;
    public bool IsPercentage { get; set; }
    public decimal Value { get; set; }
    public bool IsActive { get; set; }
    public int RedemptionCount { get; set; }
    public bool? CanDelete { get; set; }
    public string? DeleteBlockedReason { get; set; }
}

public class RewardQuery : SortedQuery
{
    public bool? IsActive { get; set; }
    public int? RewardTypeId { get; set; }
}

public class SaveLoyaltyRewardRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(200, ErrorMessage = "Name can have at most 200 characters.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Description can have at most 1000 characters.")]
    public string Description { get; set; } = string.Empty;

    [Range(1, 100000, ErrorMessage = "Points cost must be between 1 and 100000.")]
    public int PointsCost { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Select a reward type.")]
    public int RewardTypeId { get; set; }

    [Range(0.01, 10000, ErrorMessage = "Value must be between 0.01 and 10000.")]
    public decimal Value { get; set; }

    public bool IsActive { get; set; } = true;
}

public class LoyaltyBalanceDto
{
    public int Balance { get; set; }
    public int EarnedTotal { get; set; }
    public int RedeemedTotal { get; set; }
}

public class LoyaltyTransactionDto
{
    public int Id { get; set; }
    public int ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public string? ClientPictureUrl { get; set; }
    public int Points { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int? BookingId { get; set; }
    public string? RoomName { get; set; }
    public string? RoomImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TransactionQuery : PaginationQuery
{
    public int? ClientId { get; set; }

    [RegularExpression("^(Earned|Redeemed|Adjusted)$", ErrorMessage = "Type must be one of: Earned, Redeemed, Adjusted.")]
    public string? Type { get; set; }

    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }
}

public class RewardRedemptionDto
{
    public int Id { get; set; }
    public int ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public string? ClientPictureUrl { get; set; }
    public int RewardId { get; set; }
    public string RewardName { get; set; } = string.Empty;
    public string RewardTypeName { get; set; } = string.Empty;
    public bool IsPercentage { get; set; }
    public decimal Value { get; set; }
    public int PointsSpent { get; set; }
    public string Code { get; set; } = string.Empty;
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
    public int? BookingId { get; set; }
    public DateTime RedeemedAt { get; set; }
}

public class RedemptionQuery : PaginationQuery
{
    public int? ClientId { get; set; }
    public int? RewardId { get; set; }
    public bool? IsUsed { get; set; }

    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }
}

public class MyRedemptionsQuery : PaginationQuery
{
    public bool? IsUsed { get; set; }
}
