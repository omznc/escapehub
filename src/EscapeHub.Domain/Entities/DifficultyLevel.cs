namespace EscapeHub.Domain.Entities;

public class DifficultyLevel : ReferenceEntity
{
    public int Value { get; set; }

    public ICollection<Room> Rooms { get; set; } = new List<Room>();
}
