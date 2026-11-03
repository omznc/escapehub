namespace EscapeHub.Domain.Entities;

public class Promotion : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    public int PromotionTypeId { get; set; }
    public PromotionType PromotionType { get; set; } = null!;

    public decimal DiscountValue { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }

    public ICollection<Room> Rooms { get; set; } = new List<Room>();
    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
