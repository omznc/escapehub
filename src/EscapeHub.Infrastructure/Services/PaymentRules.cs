using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;

namespace EscapeHub.Infrastructure.Services;

public static class PaymentRules
{
    public const decimal MinimumAmount = 1.00m;

    public static bool IsPaid(Booking booking) => booking.Payments.Any(p => p.Status == PaymentStatus.Succeeded);

    public static string? Problem(Booking booking, DateTime now) =>
        IsPaid(booking) ? "This booking is already paid."
        : BookingStateMachine.StatusOf(booking) != BookingStatusEnum.Confirmed ? "You can pay after the staff confirm the booking."
        : booking.Schedule.StartsAt <= now ? "The session has already started."
        : booking.TotalPrice < MinimumAmount ? "The minimum payment is 1.00 KM."
        : null;
}
