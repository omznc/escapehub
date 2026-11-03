namespace EscapeHub.Domain.Entities;

public class Review : BaseEntity
{
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;

    public int ClientId { get; set; }
    public ApplicationUser Client { get; set; } = null!;

    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsHidden { get; set; }
    public bool IsDeleted { get; set; }
}
