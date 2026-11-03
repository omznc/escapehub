using System.ComponentModel.DataAnnotations;

namespace EscapeHub.Application.DTOs.Recommendations;

public class RecommendationDto
{
    public int RoomId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ShortDescription { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string ThemeName { get; set; } = string.Empty;
    public string DifficultyName { get; set; } = string.Empty;
    public int MinPlayers { get; set; }
    public int MaxPlayers { get; set; }
    public int DurationMinutes { get; set; }
    public decimal PricePerPerson { get; set; }
    public decimal PricePerBooking { get; set; }
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public double Score { get; set; }
    public bool AlreadyPlayed { get; set; }
    public string Reason { get; set; } = string.Empty;
}

public class RecommendationQuery
{
    public const int MaxPageSize = 20;

    [Range(1, int.MaxValue, ErrorMessage = "Page must be 1 or greater.")]
    public int Page { get; set; } = 1;

    [Range(1, MaxPageSize, ErrorMessage = "Page size must be between 1 and 20.")]
    public int PageSize { get; set; } = 5;
}
