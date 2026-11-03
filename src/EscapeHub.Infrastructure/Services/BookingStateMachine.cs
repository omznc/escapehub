using EscapeHub.Application.Exceptions;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;

namespace EscapeHub.Infrastructure.Services;

public static class BookingStateMachine
{
    private static readonly Dictionary<BookingStatusEnum, BookingStatusEnum[]> Transitions = new()
    {
        [BookingStatusEnum.Pending] = [BookingStatusEnum.Confirmed, BookingStatusEnum.Rejected, BookingStatusEnum.Cancelled],
        [BookingStatusEnum.Confirmed] = [BookingStatusEnum.Completed, BookingStatusEnum.NoShow, BookingStatusEnum.Cancelled]
    };

    public static BookingStatusEnum StatusOf(Booking booking) => (BookingStatusEnum)booking.BookingStatusId;

    public static bool CanMove(BookingStatusEnum from, BookingStatusEnum to) =>
        Transitions.TryGetValue(from, out var targets) && targets.Contains(to);

    public static string? MoveProblem(BookingStatusEnum from, BookingStatusEnum to) =>
        from == to ? $"This booking is already {Describe(to)}."
        : !CanMove(from, to) ? $"A {Describe(from)} booking cannot be {Describe(to)}."
        : null;

    public static void Start(Booking booking, int? changedById)
    {
        booking.BookingStatusId = (int)BookingStatusEnum.Pending;
        booking.StatusHistory.Add(new BookingStatusHistory
        {
            ToStatusId = (int)BookingStatusEnum.Pending,
            ChangedById = changedById,
            Reason = "Booking created."
        });
    }

    public static BookingStatusEnum Move(Booking booking, BookingStatusEnum to, int? changedById, string? reason)
    {
        var from = StatusOf(booking);
        if (MoveProblem(from, to) is { } problem)
            throw new ConflictException(problem);

        booking.BookingStatusId = (int)to;
        booking.StatusHistory.Add(new BookingStatusHistory
        {
            BookingId = booking.Id,
            FromStatusId = (int)from,
            ToStatusId = (int)to,
            ChangedById = changedById,
            Reason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim()
        });
        return from;
    }

    public static string Describe(BookingStatusEnum status) => status switch
    {
        BookingStatusEnum.Pending => "pending",
        BookingStatusEnum.Confirmed => "confirmed",
        BookingStatusEnum.Completed => "completed",
        BookingStatusEnum.Cancelled => "cancelled",
        BookingStatusEnum.NoShow => "marked as no-show",
        BookingStatusEnum.Rejected => "rejected",
        _ => status.ToString().ToLowerInvariant()
    };
}
