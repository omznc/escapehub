using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Schedules;

public static class SlotStatus
{
    public const string Available = "Available";
    public const string Booked = "Booked";
    public const string Past = "Past";
    public const string Blocked = "Blocked";
}

public class ScheduleDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string RoomName { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public bool IsBlocked { get; set; }
    public string Status { get; set; } = string.Empty;
    public int? BookingId { get; set; }
    public string? BookingStatus { get; set; }
    public string? ClientName { get; set; }
    public bool CanDelete { get; set; }
    public string? DeleteBlockedReason { get; set; }
}

public class SlotDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public DateTime Date { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class ScheduleQuery : PaginationQuery
{
    public int? RoomId { get; set; }

    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }

    [RegularExpression("^(Available|Booked|Past|Blocked)$", ErrorMessage = "Status must be one of: Available, Booked, Past, Blocked.")]
    public string? Status { get; set; }
}

public class SlotQuery
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a room.")]
    public int RoomId { get; set; }

    [Required(ErrorMessage = "Start date is required.")]
    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }

    [Range(1, PaginationQuery.MaxPage, ErrorMessage = "Page must be between 1 and 100000.")]
    public int Page { get; set; } = 1;

    [Range(1, PaginationQuery.MaxPageSize, ErrorMessage = "Page size must be between 1 and 100.")]
    public int PageSize { get; set; } = 100;
}

public class CreateScheduleRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a room.")]
    public int RoomId { get; set; }

    [Required(ErrorMessage = "Date is required.")]
    [DateLimit]
    public DateTime? Date { get; set; }

    [Required(ErrorMessage = "Start time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string StartTime { get; set; } = string.Empty;

    [Required(ErrorMessage = "End time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string EndTime { get; set; } = string.Empty;

    public bool IsBlocked { get; set; }
}

public class UpdateScheduleRequest
{
    [Required(ErrorMessage = "Date is required.")]
    [DateLimit]
    public DateTime? Date { get; set; }

    [Required(ErrorMessage = "Start time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string StartTime { get; set; } = string.Empty;

    [Required(ErrorMessage = "End time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string EndTime { get; set; } = string.Empty;

    public bool IsBlocked { get; set; }
}

public class GenerateSchedulesRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a room.")]
    public int RoomId { get; set; }

    [Required(ErrorMessage = "Start date is required.")]
    [DateLimit]
    public DateTime? StartDate { get; set; }

    [Required(ErrorMessage = "End date is required.")]
    [DateLimit]
    public DateTime? EndDate { get; set; }

    [Required(ErrorMessage = "Daily start time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string StartTime { get; set; } = "09:00";

    [Required(ErrorMessage = "Daily end time is required.")]
    [RegularExpression(ValidationPatterns.Time, ErrorMessage = ValidationPatterns.TimeMessage)]
    public string EndTime { get; set; } = "21:00";

    [Range(15, 480, ErrorMessage = "Slot duration must be between 15 and 480 minutes.")]
    public int SlotDurationMinutes { get; set; } = 90;

    [Range(0, 240, ErrorMessage = "Break between slots must be between 0 and 240 minutes.")]
    public int BreakMinutes { get; set; } = 30;

    [MinLength(1, ErrorMessage = "Select at least one day of the week.")]
    public List<DayOfWeek> DaysOfWeek { get; set; } = new();
}

public record GenerateSchedulesResponse(int Created, int Skipped, string Message);
