namespace EscapeHub.Domain.Entities;

public class Schedule : BaseEntity
{
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;

    public DateTime Date { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsBlocked { get; set; }

    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public DateTime StartsAt => Date.Date + StartTime;
}
