using Microsoft.AspNetCore.Identity;

namespace EscapeHub.Domain.Entities;

public class ApplicationUser : IdentityUser<int>
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public string? ProfilePictureUrl { get; set; }

    public int? CityId { get; set; }
    public City? City { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
    public ICollection<LoyaltyTransaction> LoyaltyTransactions { get; set; } = new List<LoyaltyTransaction>();
    public ICollection<RewardRedemption> RewardRedemptions { get; set; } = new List<RewardRedemption>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<Room> ManagedRooms { get; set; } = new List<Room>();
}
