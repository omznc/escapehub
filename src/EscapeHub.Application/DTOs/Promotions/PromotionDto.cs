using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Promotions;

public class PromotionDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int PromotionTypeId { get; set; }
    public string PromotionTypeName { get; set; } = string.Empty;
    public bool IsPercentage { get; set; }
    public decimal DiscountValue { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public bool IsCurrentlyValid { get; set; }
    public bool AppliesToAllRooms { get; set; }
    public List<PromotionRoomDto> Rooms { get; set; } = new();
    public int? BookingCount { get; set; }
    public bool? CanDelete { get; set; }
    public string? DeleteBlockedReason { get; set; }
}

public class PromotionRoomDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class PromotionQuery : SortedQuery
{
    public bool? IsActive { get; set; }
    public int? RoomId { get; set; }
    public bool? CurrentlyValid { get; set; }
}

public class ActivePromotionQuery : PaginationQuery
{
    public int? RoomId { get; set; }
}

public class SavePromotionRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(200, ErrorMessage = "Name can have at most 200 characters.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Description can have at most 1000 characters.")]
    public string Description { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Select a promotion type.")]
    public int PromotionTypeId { get; set; }

    [Range(0.01, 10000, ErrorMessage = "Discount value must be between 0.01 and 10000.")]
    public decimal DiscountValue { get; set; }

    [Required(ErrorMessage = "Start date is required.")]
    [DateLimit]
    public DateTime? StartDate { get; set; }

    [Required(ErrorMessage = "End date is required.")]
    [DateLimit]
    public DateTime? EndDate { get; set; }

    public bool IsActive { get; set; } = true;

    public List<int> RoomIds { get; set; } = new();
}
