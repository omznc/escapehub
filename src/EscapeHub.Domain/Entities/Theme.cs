namespace EscapeHub.Domain.Entities;

public class Theme : ReferenceEntity
{
    public ICollection<Room> Rooms { get; set; } = new List<Room>();
}
