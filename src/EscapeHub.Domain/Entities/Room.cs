namespace EscapeHub.Domain.Entities;

public class Room : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string ShortDescription { get; set; } = string.Empty;
    public string LongDescription { get; set; } = string.Empty;

    public int ThemeId { get; set; }
    public Theme Theme { get; set; } = null!;

    public int DifficultyLevelId { get; set; }
    public DifficultyLevel DifficultyLevel { get; set; } = null!;

    public int MinPlayers { get; set; }
    public int MaxPlayers { get; set; }
    public int DurationMinutes { get; set; }
    public decimal PricePerPerson { get; set; }
    public decimal PricePerBooking { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
    public string? AgeRecommendation { get; set; }

    public int? CityId { get; set; }
    public City? City { get; set; }

    public int? ManagerId { get; set; }
    public ApplicationUser? Manager { get; set; }

    public ICollection<RoomScenario> Scenarios { get; set; } = new List<RoomScenario>();
    public ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
    public ICollection<Promotion> Promotions { get; set; } = new List<Promotion>();
}
