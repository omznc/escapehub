using System.Globalization;
using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.DTOs.Reports;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class ReportService
{
    private const int DefaultRangeDays = 90;
    private const int MaxDailyRangeDays = 366;

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;

    public ReportService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BusinessClock clock)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _clock = clock;
    }

    public async Task<ReportResult<BookingsReportRow>> GetBookingsAsync(ReportQuery query)
    {
        var (from, to) = Range(query);
        var byDay = IsDaily(query);
        var groups = await Bookings(query, from, to)
            .GroupBy(b => new { b.Schedule.Date.Year, b.Schedule.Date.Month, Day = byDay ? b.Schedule.Date.Day : 1 })
            .Select(g => new
            {
                g.Key.Year,
                g.Key.Month,
                g.Key.Day,
                Total = g.Count(),
                Pending = g.Count(b => b.BookingStatusId == BookingRules.Pending),
                Confirmed = g.Count(b => b.BookingStatusId == BookingRules.Confirmed),
                Completed = g.Count(b => b.BookingStatusId == BookingRules.Completed),
                Cancelled = g.Count(b => b.BookingStatusId == BookingRules.Cancelled),
                NoShow = g.Count(b => b.BookingStatusId == BookingRules.NoShow),
                Rejected = g.Count(b => b.BookingStatusId == BookingRules.Rejected)
            })
            .ToListAsync();

        var rows = groups
            .Select(g => new BookingsReportRow(new DateTime(g.Year, g.Month, g.Day), g.Total, g.Pending, g.Confirmed, g.Completed, g.Cancelled, g.NoShow, g.Rejected))
            .OrderBy(r => r.Date);
        return Result("Bookings", from, to, rows);
    }

    public async Task<ReportResult<RevenueReportRow>> GetRevenueAsync(ReportQuery query)
    {
        var (from, to) = Range(query);
        var byDay = IsDaily(query);
        var groups = await Bookings(query, from, to)
            .Where(b => b.BookingStatusId == BookingRules.Completed)
            .GroupBy(b => new { b.Schedule.Date.Year, b.Schedule.Date.Month, Day = byDay ? b.Schedule.Date.Day : 1 })
            .Select(g => new { g.Key.Year, g.Key.Month, g.Key.Day, Count = g.Count(), Revenue = g.Sum(b => b.TotalPrice), Discounts = g.Sum(b => b.DiscountApplied) })
            .ToListAsync();

        var rows = groups
            .Select(g => new { Date = new DateTime(g.Year, g.Month, g.Day), g.Count, g.Revenue, g.Discounts })
            .OrderBy(g => g.Date)
            .Select(g => new RevenueReportRow(g.Date.ToString(byDay ? "yyyy-MM-dd" : "yyyy-MM", CultureInfo.InvariantCulture), g.Count, g.Revenue, g.Discounts));
        return Result("Revenue", from, to, rows);
    }

    public async Task<ReportResult<OccupancyReportRow>> GetOccupancyAsync(ReportQuery query)
    {
        var (from, to) = Range(query);
        var occupancy = await OccupancyQuery.ByRoomAsync(_db, from, to, _access.ManagerScope, query.RoomId);
        var rows = occupancy
            .Select(o => new OccupancyReportRow(o.RoomId, o.RoomName, o.TotalSlots, o.BookedSlots, o.Percent))
            .OrderByDescending(r => r.OccupancyPercent).ThenBy(r => r.RoomName);
        return Result("Occupancy", from, to, rows);
    }

    public async Task<ReportResult<TopRoomReportRow>> GetTopRoomsAsync(ReportQuery query)
    {
        var (from, to) = Range(query);
        var groups = await Bookings(query, from, to)
            .Where(BookingRules.IsActive)
            .GroupBy(b => new { b.Schedule.RoomId, b.Schedule.Room.Name })
            .Select(g => new
            {
                g.Key.RoomId,
                g.Key.Name,
                Count = g.Count(),
                Revenue = g.Where(b => b.BookingStatusId == BookingRules.Completed).Sum(b => b.TotalPrice),
                Players = g.Average(b => (double)b.PlayerCount)
            })
            .OrderByDescending(g => g.Count).ThenByDescending(g => g.Revenue)
            .Take(query.Top)
            .ToListAsync();

        var rows = groups.Select(g => new TopRoomReportRow(g.RoomId, g.Name, g.Count, g.Revenue, Math.Round(g.Players, 1)));
        return Result("Top rooms", from, to, rows);
    }

    public Task<ReportResult<TopClientReportRow>> GetTopClientsAsync(ReportQuery query) =>
        GetClientsAsync(query, "Top clients by bookings", bySpending: false);

    public Task<ReportResult<TopClientReportRow>> GetTopClientsBySpendingAsync(ReportQuery query) =>
        GetClientsAsync(query, "Top clients by spending", bySpending: true);

    public async Task<ReportResult<RatingReportRow>> GetRatingsAsync(ReportQuery query)
    {
        var (from, to) = Range(query);
        var (start, end) = (_clock.UtcDayStart(from), _clock.UtcDayEnd(to));
        var reviews = _db.Reviews.AsNoTracking().Where(r => !r.IsHidden && r.CreatedAt >= start && r.CreatedAt < end);
        if (_access.ManagerScope is { } managerId) reviews = reviews.Where(r => r.Room.ManagerId == managerId);
        if (query.RoomId.HasValue) reviews = reviews.Where(r => r.RoomId == query.RoomId);

        var groups = await reviews
            .GroupBy(r => new { r.RoomId, r.Room.Name })
            .Select(g => new
            {
                g.Key.RoomId,
                g.Key.Name,
                Average = g.Average(r => (double)r.Rating),
                Count = g.Count(),
                One = g.Count(r => r.Rating == 1),
                Two = g.Count(r => r.Rating == 2),
                Three = g.Count(r => r.Rating == 3),
                Four = g.Count(r => r.Rating == 4),
                Five = g.Count(r => r.Rating == 5)
            })
            .ToListAsync();

        var rows = groups
            .Select(g => new RatingReportRow(g.RoomId, g.Name, Math.Round(g.Average, 2), g.Count, g.One, g.Two, g.Three, g.Four, g.Five))
            .OrderByDescending(r => r.AverageRating).ThenByDescending(r => r.ReviewCount);
        return Result("Ratings", from, to, rows);
    }

    public async Task<ReportResult<RedemptionReportRow>> GetRedemptionsAsync(ReportQuery query)
    {
        if (!_currentUser.IsAdmin)
            throw new ForbiddenException("Only an administrator can see the loyalty report.");

        var (from, to) = Range(query);
        var (start, end) = (_clock.UtcDayStart(from), _clock.UtcDayEnd(to));
        var groups = await _db.RewardRedemptions.AsNoTracking()
            .Where(r => r.CreatedAt >= start && r.CreatedAt < end)
            .GroupBy(r => new { r.LoyaltyRewardId, r.LoyaltyReward.Name })
            .Select(g => new { g.Key.LoyaltyRewardId, g.Key.Name, Count = g.Count(), Points = g.Sum(r => r.PointsSpent), Used = g.Count(r => r.IsUsed) })
            .OrderByDescending(g => g.Count)
            .ToListAsync();

        var rows = groups.Select(g => new RedemptionReportRow(g.LoyaltyRewardId, g.Name, g.Count, g.Points, g.Used, g.Count - g.Used));
        return Result("Loyalty redemptions", from, to, rows);
    }

    public async Task<ReportTable> GetTableAsync(string report, ReportQuery query) => report switch
    {
        ReportNames.Bookings => Table(await GetBookingsAsync(query),
            ["Date", "Total", "Pending", "Confirmed", "Completed", "Cancelled", "No-show", "Rejected"],
            r => [Format(r.Date), Format(r.Total), Format(r.Pending), Format(r.Confirmed), Format(r.Completed), Format(r.Cancelled), Format(r.NoShow), Format(r.Rejected)]),
        ReportNames.Revenue => Table(await GetRevenueAsync(query),
            ["Period", "Bookings", "Revenue", "Discounts"],
            r => [r.Period, Format(r.Bookings), Format(r.Revenue), Format(r.Discounts)]),
        ReportNames.Occupancy => Table(await GetOccupancyAsync(query),
            ["Room", "Slots", "Booked", "Occupancy %"],
            r => [r.RoomName, Format(r.TotalSlots), Format(r.BookedSlots), Format(r.OccupancyPercent)]),
        ReportNames.TopRooms => Table(await GetTopRoomsAsync(query),
            ["Room", "Bookings", "Revenue", "Average players"],
            r => [r.RoomName, Format(r.Bookings), Format(r.Revenue), Format(r.AveragePlayers)]),
        ReportNames.TopClients => ClientTable(await GetTopClientsAsync(query)),
        ReportNames.TopClientsBySpending => ClientTable(await GetTopClientsBySpendingAsync(query)),
        ReportNames.Ratings => Table(await GetRatingsAsync(query),
            ["Room", "Average", "Reviews", "1", "2", "3", "4", "5"],
            r => [r.RoomName, Format(r.AverageRating), Format(r.ReviewCount), Format(r.OneStar), Format(r.TwoStars), Format(r.ThreeStars), Format(r.FourStars), Format(r.FiveStars)]),
        ReportNames.LoyaltyRedemptions => Table(await GetRedemptionsAsync(query),
            ["Reward", "Redemptions", "Points spent", "Used", "Unused"],
            r => [r.RewardName, Format(r.Redemptions), Format(r.PointsSpent), Format(r.Used), Format(r.Unused)]),
        _ => throw new NotFoundException($"The report '{report}' does not exist.")
    };

    private async Task<ReportResult<TopClientReportRow>> GetClientsAsync(ReportQuery query, string title, bool bySpending)
    {
        var (from, to) = Range(query);
        var grouped = Bookings(query, from, to)
            .Where(BookingRules.IsActive)
            .GroupBy(b => new { b.ClientId, b.Client.FirstName, b.Client.LastName, b.Client.Email })
            .Select(g => new
            {
                g.Key.ClientId,
                Name = g.Key.FirstName + " " + g.Key.LastName,
                g.Key.Email,
                Count = g.Count(),
                Spent = g.Where(b => b.BookingStatusId == BookingRules.Completed).Sum(b => b.TotalPrice)
            });
        var ordered = bySpending
            ? grouped.OrderByDescending(g => g.Spent).ThenByDescending(g => g.Count)
            : grouped.OrderByDescending(g => g.Count).ThenByDescending(g => g.Spent);

        var groups = await ordered.Take(query.Top).ToListAsync();
        return Result(title, from, to, groups.Select(g => new TopClientReportRow(g.ClientId, g.Name, g.Email ?? string.Empty, g.Count, g.Spent)));
    }

    private IQueryable<Booking> Bookings(ReportQuery query, DateTime from, DateTime to)
    {
        var bookings = _db.Bookings.AsNoTracking().Where(b => b.Schedule.Date >= from && b.Schedule.Date <= to);
        if (_access.ManagerScope is { } managerId) bookings = bookings.Where(b => b.Schedule.Room.ManagerId == managerId);
        if (query.RoomId.HasValue) bookings = bookings.Where(b => b.Schedule.RoomId == query.RoomId);
        return bookings;
    }

    private (DateTime From, DateTime To) Range(ReportQuery query)
    {
        var to = (query.To ?? _clock.Today).Date;
        var from = (query.From ?? to.AddDays(-DefaultRangeDays)).Date;
        if (from > to)
            throw new BusinessException("The start date must be on or before the end date.", "from");
        if (IsDaily(query) && (to - from).TotalDays > MaxDailyRangeDays)
            throw new BusinessException($"With day grouping, the end date can be at most {MaxDailyRangeDays} days after the start date. Select an earlier end date or group by month.", "to");
        return (from, to);
    }

    private static bool IsDaily(ReportQuery query) => query.GroupBy == ReportOptions.Day;

    private static ReportResult<T> Result<T>(string title, DateTime from, DateTime to, IEnumerable<T> rows) =>
        new() { Title = title, From = from, To = to, Rows = rows.ToList() };

    private static ReportTable ClientTable(ReportResult<TopClientReportRow> result) =>
        Table(result, ["Client", "Email", "Bookings", "Total spent"],
            r => [r.ClientName, r.Email, Format(r.Bookings), Format(r.TotalSpent)]);

    private static ReportTable Table<T>(ReportResult<T> result, List<string> columns, Func<T, List<string>> row) => new()
    {
        Title = result.Title,
        From = result.From,
        To = result.To,
        Columns = columns,
        Rows = result.Rows.Select(row).ToList()
    };

    private static string Format(int value) => value.ToString(CultureInfo.InvariantCulture);
    private static string Format(double value) => value.ToString("0.##", CultureInfo.InvariantCulture);
    private static string Format(decimal value) => value.ToString("0.00", CultureInfo.InvariantCulture);
    private static string Format(DateTime value) => value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
}
