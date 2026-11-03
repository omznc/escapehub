namespace EscapeHub.Application.DTOs.Dashboard;

public class DashboardStatsDto
{
    public int TodayBookings { get; set; }
    public int WeekBookings { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public double AverageRating { get; set; }
    public int ActivePromotions { get; set; }
    public int ActiveRooms { get; set; }
    public int PendingBookings { get; set; }
    public List<DayCountDto> BookingsByDay { get; set; } = new();
    public List<RoomValueDto> RevenueByRoom { get; set; } = new();
    public List<RoomValueDto> OccupancyByRoom { get; set; } = new();
    public List<TopClientDto> TopClients { get; set; } = new();
    public List<DashboardReviewDto> LatestReviews { get; set; } = new();
    public List<UpcomingSessionDto> UpcomingSessions { get; set; } = new();
}

public record DayCountDto(DateTime Date, int Count);

public record RoomValueDto(int RoomId, string RoomName, decimal Value);

public record TopClientDto(int ClientId, string ClientName, int Bookings, decimal TotalSpent);

public record DashboardReviewDto(int Id, string RoomName, string ClientName, int Rating, string? Comment, bool IsHidden, DateTime CreatedAt);

public record UpcomingSessionDto(int BookingId, string RoomName, string ClientName, DateTime Date, string StartTime, int PlayerCount, string Status);
