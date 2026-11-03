namespace EscapeHub.Domain.Entities;

public class BookingStatus : ReferenceEntity
{
    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
