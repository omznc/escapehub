using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Rooms;

public class RoomListItemDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ShortDescription { get; set; } = string.Empty;
    public int ThemeId { get; set; }
    public string ThemeName { get; set; } = string.Empty;
    public int DifficultyLevelId { get; set; }
    public string DifficultyName { get; set; } = string.Empty;
    public int DifficultyValue { get; set; }
    public int MinPlayers { get; set; }
    public int MaxPlayers { get; set; }
    public int DurationMinutes { get; set; }
    public decimal PricePerPerson { get; set; }
    public decimal PricePerBooking { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public int? CityId { get; set; }
    public string? CityName { get; set; }
    public int? ManagerId { get; set; }
    public string? ManagerName { get; set; }
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public int? BookingCount { get; set; }
    public bool? CanDelete { get; set; }
    public string? DeleteBlockedReason { get; set; }
}

public class RoomDto : RoomListItemDto
{
    public string LongDescription { get; set; } = string.Empty;
    public string? AgeRecommendation { get; set; }
    public List<RoomScenarioSummaryDto> Scenarios { get; set; } = new();
}

public class RoomScenarioSummaryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Story { get; set; } = string.Empty;
    public string? DifficultyName { get; set; }
    public string? HintPolicy { get; set; }
}

public class RoomStatsDto
{
    public int RoomId { get; set; }
    public DateTime From { get; set; }
    public DateTime To { get; set; }
    public int TotalBookings { get; set; }
    public int CompletedBookings { get; set; }
    public int CancelledBookings { get; set; }
    public decimal Revenue { get; set; }
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public int TotalSlots { get; set; }
    public int BookedSlots { get; set; }
    public double OccupancyPercent { get; set; }
    public int RecordedResults { get; set; }
    public double EscapeRatePercent { get; set; }
    public double? AverageCompletionMinutes { get; set; }
}

public static class RoomSortOptions
{
    public const string Rating = "rating";
    public const string Easiest = "easiest";
    public const string Hardest = "hardest";
    public const string Cheapest = "cheapest";
    public const string Popular = "popular";
    public const string Newest = ListSortOptions.Newest;
}

public class RoomQuery : PaginationQuery
{
    public int? ThemeId { get; set; }
    public int? DifficultyLevelId { get; set; }
    public int? CityId { get; set; }
    public int? ManagerId { get; set; }

    [Range(1, 50, ErrorMessage = "Minimum players must be between 1 and 50.")]
    public int? MinPlayers { get; set; }

    [Range(1, 50, ErrorMessage = "Maximum players must be between 1 and 50.")]
    public int? MaxPlayers { get; set; }

    [Range(1, 50, ErrorMessage = "Party size must be between 1 and 50.")]
    public int? PartySize { get; set; }

    [Range(0, 100000, ErrorMessage = "Minimum price must be between 0 and 100000.")]
    public decimal? MinPrice { get; set; }

    [Range(0, 100000, ErrorMessage = "Maximum price must be between 0 and 100000.")]
    public decimal? MaxPrice { get; set; }

    [DateLimit]
    public DateTime? AvailableDate { get; set; }

    public bool? IsActive { get; set; }

    [RegularExpression("^(" + RoomSortOptions.Rating + "|" + RoomSortOptions.Easiest + "|" + RoomSortOptions.Hardest + "|" +
                       RoomSortOptions.Cheapest + "|" + RoomSortOptions.Popular + "|" + RoomSortOptions.Newest + ")$", ErrorMessage = "Sort must be one of: rating, easiest, hardest, cheapest, popular, newest.")]
    public string? SortBy { get; set; }
}

public class SaveRoomRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(200, ErrorMessage = "Name can have at most 200 characters.")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Short description is required.")]
    [StringLength(500, ErrorMessage = "Short description can have at most 500 characters.")]
    public string ShortDescription { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Long description can have at most 2000 characters.")]
    public string LongDescription { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Select a theme.")]
    public int ThemeId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Select a difficulty level.")]
    public int DifficultyLevelId { get; set; }

    [Range(1, 50, ErrorMessage = "Minimum players must be between 1 and 50.")]
    public int MinPlayers { get; set; }

    [Range(1, 50, ErrorMessage = "Maximum players must be between 1 and 50.")]
    public int MaxPlayers { get; set; }

    [Range(15, 240, ErrorMessage = "Duration must be between 15 and 240 minutes.")]
    public int DurationMinutes { get; set; }

    [Range(0, 1000, ErrorMessage = "Price per person must be between 0 and 1000.")]
    public decimal PricePerPerson { get; set; }

    [Range(0, 10000, ErrorMessage = "Price per booking must be between 0 and 10000.")]
    public decimal PricePerBooking { get; set; }

    public bool IsActive { get; set; } = true;

    [StringLength(100, ErrorMessage = "Age recommendation can have at most 100 characters.")]
    public string? AgeRecommendation { get; set; }

    public int? CityId { get; set; }
    public int? ManagerId { get; set; }
}
