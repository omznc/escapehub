namespace EscapeHub.Domain.Entities;

public class RoomScenario : BaseEntity
{
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string Story { get; set; } = string.Empty;

    public int? DifficultyOverrideId { get; set; }
    public DifficultyLevel? DifficultyOverride { get; set; }

    public string? HintPolicy { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
}
