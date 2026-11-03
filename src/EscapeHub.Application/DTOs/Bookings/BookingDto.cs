using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Bookings;

public class BookingListItemDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string RoomName { get; set; } = string.Empty;
    public string? RoomImageUrl { get; set; }
    public string ThemeName { get; set; } = string.Empty;
    public int ScheduleId { get; set; }
    public DateTime Date { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public int ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public string? ClientPictureUrl { get; set; }
    public int StatusId { get; set; }
    public string Status { get; set; } = string.Empty;
    public int PlayerCount { get; set; }
    public decimal TotalPrice { get; set; }
    public bool HasResult { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BookingDto : BookingListItemDto
{
    public string ClientEmail { get; set; } = string.Empty;
    public decimal Subtotal { get; set; }
    public decimal DiscountApplied { get; set; }
    public int? PromotionId { get; set; }
    public string? PromotionName { get; set; }
    public int? RedemptionId { get; set; }
    public string? VoucherCode { get; set; }
    public string? RewardName { get; set; }
    public string? Notes { get; set; }
    public List<string> ParticipantNames { get; set; } = new();
    public RoomResultDto? Result { get; set; }
    public int PointsEarned { get; set; }
    public bool CanCancel { get; set; }
    public string? CancelBlockedReason { get; set; }
    public bool CanReview { get; set; }
    public List<string> AllowedActions { get; set; } = new();
    public Dictionary<string, string> BlockedReasons { get; set; } = new();
    public List<BookingStatusHistoryDto> StatusHistory { get; set; } = new();
}

public class RoomResultDto
{
    public bool Escaped { get; set; }
    public int? CompletionTimeMinutes { get; set; }
    public int? HintsUsed { get; set; }
    public string? ManagerNotes { get; set; }
    public int? Score { get; set; }
    public string RecordedByName { get; set; } = string.Empty;
    public DateTime RecordedAt { get; set; }
}

public class BookingStatusHistoryDto
{
    public string? FromStatus { get; set; }
    public string ToStatus { get; set; } = string.Empty;
    public string? ChangedByName { get; set; }
    public string? Reason { get; set; }
    public DateTime ChangedAt { get; set; }
}

public class BookingQuery : SortedQuery
{
    public int? StatusId { get; set; }
    public int? RoomId { get; set; }
    public int? ClientId { get; set; }

    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }
}

public class MyBookingsQuery : PaginationQuery
{
    public bool Upcoming { get; set; } = true;
}

public class CreateBookingRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a time slot.")]
    public int ScheduleId { get; set; }

    public int? ClientId { get; set; }

    [Range(1, 50, ErrorMessage = "Player count must be between 1 and 50.")]
    public int PlayerCount { get; set; }

    public int? PromotionId { get; set; }
    public int? RedemptionId { get; set; }

    [StringLength(50, ErrorMessage = "Voucher code can have at most 50 characters.")]
    public string? VoucherCode { get; set; }

    [StringLength(1000, ErrorMessage = "Notes can have at most 1000 characters.")]
    public string? Notes { get; set; }

    public List<string> ParticipantNames { get; set; } = new();
}

public class BookingQuoteDto
{
    public decimal Subtotal { get; set; }
    public decimal PromotionDiscount { get; set; }
    public decimal VoucherDiscount { get; set; }
    public decimal DiscountApplied { get; set; }
    public decimal TotalPrice { get; set; }
    public string? PromotionName { get; set; }
    public string? RewardName { get; set; }
}

public class ReasonRequest
{
    [Required(ErrorMessage = "Enter a reason for the cancellation.")]
    [StringLength(500, MinimumLength = 3, ErrorMessage = "Reason must have between 3 and 500 characters.")]
    public string? Reason { get; set; }
}

public class RejectBookingRequest
{
    [Required(ErrorMessage = "Reason is required when you reject a booking.")]
    [StringLength(500, MinimumLength = 3, ErrorMessage = "Reason must have between 3 and 500 characters.")]
    public string? Reason { get; set; }
}

public class SaveRoomResultRequest
{
    public bool Escaped { get; set; }

    [Range(1, 480, ErrorMessage = "Completion time must be between 1 and 480 minutes.")]
    public int? CompletionTimeMinutes { get; set; }

    [Range(0, 50, ErrorMessage = "Hints used must be between 0 and 50.")]
    public int? HintsUsed { get; set; }

    [StringLength(2000, ErrorMessage = "Manager notes can have at most 2000 characters.")]
    public string? ManagerNotes { get; set; }

    [Range(0, 100, ErrorMessage = "Score must be between 0 and 100.")]
    public int? Score { get; set; }
}

public class CompleteBookingRequest
{
    public SaveRoomResultRequest? Result { get; set; }
}
