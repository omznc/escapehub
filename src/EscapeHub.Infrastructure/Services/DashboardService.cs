using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.DTOs.Dashboard;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class DashboardService
{
    private const int ChartDays = 14;
    private const int StatsDays = 30;
    private const int ListSize = 5;
    private const int UpcomingSize = 10;

    private readonly AppDbContext _db;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;

    public DashboardService(AppDbContext db, RoomAccess access, BusinessClock clock)
    {
        _db = db;
        _access = access;
        _clock = clock;
    }

    public async Task<DashboardStatsDto> GetAsync()
    {
        var now = _clock.Now;
        var today = now.Date;
        var stats = new DashboardStatsDto();
        await LoadCountersAsync(stats, today);
        stats.BookingsByDay = await GetBookingsByDayAsync(today);
        stats.RevenueByRoom = await GetRevenueByRoomAsync(today);
        stats.OccupancyByRoom = await GetOccupancyByRoomAsync(today);
        stats.TopClients = await GetTopClientsAsync(today);
        stats.LatestReviews = await GetLatestReviewsAsync();
        stats.UpcomingSessions = await GetUpcomingAsync(now);
        return stats;
    }

    private async Task LoadCountersAsync(DashboardStatsDto stats, DateTime today)
    {
        var weekStart = today.AddDays(-6);
        var monthStart = new DateTime(today.Year, today.Month, 1);
        var counters = await Bookings()
            .Where(b => b.Schedule.Date >= monthStart || b.Schedule.Date >= weekStart || b.BookingStatusId == BookingRules.Pending)
            .GroupBy(_ => 1)
            .OrderBy(g => g.Key)
            .Select(g => new
            {
                Today = g.Count(b => b.Schedule.Date == today && b.BookingStatusId != BookingRules.Cancelled && b.BookingStatusId != BookingRules.Rejected),
                Week = g.Count(b => b.Schedule.Date >= weekStart && b.Schedule.Date <= today && b.BookingStatusId != BookingRules.Cancelled && b.BookingStatusId != BookingRules.Rejected),
                Revenue = g.Where(b => b.Schedule.Date >= monthStart && b.BookingStatusId == BookingRules.Completed).Sum(b => (decimal?)b.TotalPrice) ?? 0,
                Pending = g.Count(b => b.BookingStatusId == BookingRules.Pending)
            })
            .FirstOrDefaultAsync();

        stats.TodayBookings = counters?.Today ?? 0;
        stats.WeekBookings = counters?.Week ?? 0;
        stats.MonthlyRevenue = counters?.Revenue ?? 0;
        stats.PendingBookings = counters?.Pending ?? 0;
        stats.AverageRating = Math.Round(await Reviews(includeHidden: false).AverageAsync(r => (double?)r.Rating) ?? 0, 2);
        stats.ActiveRooms = await _access.ManagedRooms().CountAsync(r => r.IsActive);
        stats.ActivePromotions = await _access.VisiblePromotions().CountAsync(p => p.IsActive && p.StartDate <= today && p.EndDate >= today);
    }

    private async Task<List<DayCountDto>> GetBookingsByDayAsync(DateTime today)
    {
        var start = today.AddDays(1 - ChartDays);
        var counts = await Bookings()
            .Where(BookingRules.IsActive)
            .Where(b => b.Schedule.Date >= start && b.Schedule.Date <= today)
            .GroupBy(b => b.Schedule.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.Date, g => g.Count);

        return Enumerable.Range(0, ChartDays)
            .Select(i => start.AddDays(i))
            .Select(day => new DayCountDto(day, counts.GetValueOrDefault(day)))
            .ToList();
    }

    private async Task<List<RoomValueDto>> GetRevenueByRoomAsync(DateTime today)
    {
        var start = today.AddDays(-StatsDays);
        var rows = await Bookings()
            .Where(b => b.BookingStatusId == BookingRules.Completed && b.Schedule.Date >= start)
            .GroupBy(b => new { b.Schedule.RoomId, b.Schedule.Room.Name })
            .Select(g => new { g.Key.RoomId, g.Key.Name, Value = g.Sum(b => b.TotalPrice) })
            .OrderByDescending(g => g.Value)
            .ToListAsync();
        return rows.Select(r => new RoomValueDto(r.RoomId, r.Name, r.Value)).ToList();
    }

    private async Task<List<RoomValueDto>> GetOccupancyByRoomAsync(DateTime today)
    {
        var occupancy = await OccupancyQuery.ByRoomAsync(_db, today.AddDays(-StatsDays), today, _access.ManagerScope, null);
        return occupancy
            .Select(o => new RoomValueDto(o.RoomId, o.RoomName, (decimal)o.Percent))
            .OrderByDescending(r => r.Value)
            .ToList();
    }

    private async Task<List<TopClientDto>> GetTopClientsAsync(DateTime today)
    {
        var start = today.AddDays(-StatsDays * 3);
        var rows = await Bookings()
            .Where(BookingRules.IsActive)
            .Where(b => b.Schedule.Date >= start)
            .GroupBy(b => new { b.ClientId, b.Client.FirstName, b.Client.LastName })
            .Select(g => new
            {
                g.Key.ClientId,
                Name = g.Key.FirstName + " " + g.Key.LastName,
                Count = g.Count(),
                Spent = g.Where(b => b.BookingStatusId == BookingRules.Completed).Sum(b => b.TotalPrice)
            })
            .OrderByDescending(g => g.Count).ThenByDescending(g => g.Spent)
            .Take(ListSize)
            .ToListAsync();
        return rows.Select(r => new TopClientDto(r.ClientId, r.Name, r.Count, r.Spent)).ToList();
    }

    private Task<List<DashboardReviewDto>> GetLatestReviewsAsync() =>
        Reviews(includeHidden: true)
            .OrderByDescending(r => r.CreatedAt)
            .Take(ListSize)
            .Select(r => new DashboardReviewDto(r.Id, r.Room.Name, r.Client.FirstName + " " + r.Client.LastName, r.Rating, r.Comment, r.IsHidden, r.CreatedAt))
            .ToListAsync();

    private async Task<List<UpcomingSessionDto>> GetUpcomingAsync(DateTime now)
    {
        var rows = await Bookings()
            .Where(BookingRules.IsUpcoming(now))
            .OrderBy(b => b.Schedule.Date).ThenBy(b => b.Schedule.StartTime)
            .Take(UpcomingSize)
            .Select(b => new
            {
                b.Id,
                Room = b.Schedule.Room.Name,
                Client = b.Client.FirstName + " " + b.Client.LastName,
                b.Schedule.Date,
                b.Schedule.StartTime,
                b.PlayerCount,
                Status = b.BookingStatus.Name
            })
            .ToListAsync();
        return rows.Select(r => new UpcomingSessionDto(r.Id, r.Room, r.Client, r.Date, BookingMapper.FormatTime(r.StartTime), r.PlayerCount, r.Status)).ToList();
    }

    private IQueryable<Booking> Bookings()
    {
        var bookings = _db.Bookings.AsNoTracking();
        return _access.ManagerScope is { } managerId ? bookings.Where(b => b.Schedule.Room.ManagerId == managerId) : bookings;
    }

    private IQueryable<Review> Reviews(bool includeHidden)
    {
        var reviews = _db.Reviews.AsNoTracking().Where(r => includeHidden || !r.IsHidden);
        return _access.ManagerScope is { } managerId ? reviews.Where(r => r.Room.ManagerId == managerId) : reviews;
    }
}
