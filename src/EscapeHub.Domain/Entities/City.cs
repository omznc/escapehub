namespace EscapeHub.Domain.Entities;

public class City : ReferenceEntity
{
    public int CountryId { get; set; }
    public Country Country { get; set; } = null!;

    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
    public ICollection<Room> Rooms { get; set; } = new List<Room>();
}
