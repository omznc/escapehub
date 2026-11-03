using Microsoft.EntityFrameworkCore;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public record RoomOccupancy(int RoomId, string RoomName, int TotalSlots, int BookedSlots)
{
    public double Percent => OccupancyQuery.Percent(BookedSlots, TotalSlots);
}

public static class OccupancyQuery
{
    public static double Percent(int part, int total) => total == 0 ? 0 : Math.Round(100.0 * part / total, 1);

    public static async Task<List<RoomOccupancy>> ByRoomAsync(AppDbContext db, DateTime from, DateTime to, int? managerId, int? roomId)
    {
        var slots = db.Schedules.AsNoTracking().Where(s => s.Date >= from && s.Date <= to && !s.IsBlocked);
        var bookings = db.Bookings.AsNoTracking().Where(BookingRules.IsActive)
            .Where(b => b.Schedule.Date >= from && b.Schedule.Date <= to && !b.Schedule.IsBlocked);
        if (managerId.HasValue)
        {
            slots = slots.Where(s => s.Room.ManagerId == managerId);
            bookings = bookings.Where(b => b.Schedule.Room.ManagerId == managerId);
        }
        if (roomId.HasValue)
        {
            slots = slots.Where(s => s.RoomId == roomId);
            bookings = bookings.Where(b => b.Schedule.RoomId == roomId);
        }

        var totals = await slots.GroupBy(s => new { s.RoomId, s.Room.Name })
            .Select(g => new { g.Key.RoomId, g.Key.Name, Count = g.Count() })
            .ToListAsync();
        var booked = await bookings.GroupBy(b => b.Schedule.RoomId)
            .Select(g => new { RoomId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.RoomId, g => g.Count);
        return totals.Select(t => new RoomOccupancy(t.RoomId, t.Name, t.Count, booked.GetValueOrDefault(t.RoomId))).ToList();
    }
}
