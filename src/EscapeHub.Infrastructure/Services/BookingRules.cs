using System.Linq.Expressions;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;

namespace EscapeHub.Infrastructure.Services;

public static class BookingRules
{
    public const int Pending = (int)BookingStatusEnum.Pending;
    public const int Confirmed = (int)BookingStatusEnum.Confirmed;
    public const int Cancelled = (int)BookingStatusEnum.Cancelled;
    public const int Rejected = (int)BookingStatusEnum.Rejected;
    public const int Completed = (int)BookingStatusEnum.Completed;
    public const int NoShow = (int)BookingStatusEnum.NoShow;

    public static readonly Expression<Func<Booking, bool>> IsActive =
        b => b.BookingStatusId != Cancelled && b.BookingStatusId != Rejected;

    public static bool IsActiveStatus(int statusId) => statusId != Cancelled && statusId != Rejected;

    public static Expression<Func<Booking, bool>> IsUpcoming(DateTime now)
    {
        var today = now.Date;
        var time = now.TimeOfDay;
        return b => (b.BookingStatusId == Pending || b.BookingStatusId == Confirmed) &&
                    (b.Schedule.Date > today || (b.Schedule.Date == today && b.Schedule.StartTime > time));
    }

    public static Expression<Func<Schedule, bool>> IsOpen(DateTime now)
    {
        var today = now.Date;
        var time = now.TimeOfDay;
        return s => !s.IsBlocked && (s.Date > today || (s.Date == today && s.StartTime > time)) &&
                    !s.Bookings.AsQueryable().Any(IsActive);
    }
}
