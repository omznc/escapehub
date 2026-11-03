using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Identity;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Worker.Handlers;

public class BookingEventHandler
{
    private readonly AppDbContext _db;
    private readonly Notifier _notifier;
    private readonly ILogger<BookingEventHandler> _logger;

    public BookingEventHandler(AppDbContext db, Notifier notifier, ILogger<BookingEventHandler> logger)
    {
        _db = db;
        _notifier = notifier;
        _logger = logger;
    }

    public async Task HandleAsync(BookingCreatedEvent message)
    {
        var booking = await LoadAsync(message.BookingId);
        var notifications = new List<(ApplicationUser, NotificationMessage)>
        {
            (booking.Client, new NotificationMessage(NotificationType.BookingCreated, "Booking received",
                $"We received your booking for {BookingMapper.Describe(booking)}. We will confirm it soon."))
        };
        var staffMessage = new NotificationMessage(NotificationType.BookingCreated, "New booking",
            $"{FullName(booking.Client)} booked {BookingMapper.Describe(booking)} for {booking.PlayerCount} players. Confirm or reject the booking.");
        notifications.AddRange((await StaffForAsync(booking)).Select(staff => (staff, staffMessage)));
        await _notifier.NotifyAsync(notifications);
    }

    public async Task HandleAsync(BookingStatusChangedEvent message)
    {
        var booking = await LoadAsync(message.BookingId);
        var status = (BookingStatusEnum)message.ToStatusId;
        var notifications = new List<(ApplicationUser, NotificationMessage)>();
        if (StatusMessage(booking, status, message.Reason) is { } notification)
            notifications.Add((booking.Client, notification));
        if (status == BookingStatusEnum.Cancelled && message.ChangedById == booking.ClientId)
        {
            var staffMessage = new NotificationMessage(NotificationType.BookingCancelled, "Booking cancelled by the client",
                $"{FullName(booking.Client)} cancelled the booking for {BookingMapper.Describe(booking)}. Reason: {message.Reason}");
            notifications.AddRange((await StaffForAsync(booking)).Select(staff => (staff, staffMessage)));
        }
        await _notifier.NotifyAsync(notifications);
    }

    public async Task HandleAsync(BookingCompletedEvent message)
    {
        var booking = await LoadAsync(message.BookingId);
        if (await _db.LoyaltyTransactions.AnyAsync(t => t.BookingId == booking.Id && t.TransactionType == TransactionType.Earned))
        {
            _logger.LogInformation("Points for booking {BookingId} were already awarded", booking.Id);
            return;
        }

        var completed = new NotificationMessage(NotificationType.BookingCompleted, "Thank you for playing",
            $"Your session in {booking.Schedule.Room.Name} is complete. You can now leave a review.");
        var points = await CalculatePointsAsync(booking);
        _db.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            ClientId = booking.ClientId,
            BookingId = booking.Id,
            Points = points,
            TransactionType = TransactionType.Earned,
            Description = $"Session in {booking.Schedule.Room.Name}"
        });
        var awarded = new NotificationMessage(NotificationType.LoyaltyPointsAwarded, "Loyalty points added",
            $"You earned {points} loyalty points for your session in {booking.Schedule.Room.Name}.");
        await _notifier.NotifyAsync(booking.Client, completed, awarded);
        _logger.LogInformation("Awarded {Points} points to client {ClientId} for booking {BookingId}", points, booking.ClientId, booking.Id);
    }

    public async Task HandleAsync(ResultRecordedEvent message)
    {
        var booking = await LoadAsync(message.BookingId);
        var result = await _db.RoomResults.AsNoTracking().FirstAsync(r => r.BookingId == booking.Id);
        var outcome = result.Escaped
            ? $"You escaped from {booking.Schedule.Room.Name}" + (result.CompletionTimeMinutes is { } minutes ? $" in {minutes} minutes" : string.Empty)
            : $"You did not escape from {booking.Schedule.Room.Name} this time";
        await _notifier.NotifyAsync(booking.Client, new NotificationMessage(NotificationType.ResultRecorded, "Your result is ready",
            $"{outcome}. Hints used: {result.HintsUsed ?? 0}."));
    }

    public async Task HandleAsync(SessionReminderEvent message)
    {
        var booking = await LoadAsync(message.BookingId);
        await _notifier.NotifyAsync(booking.Client, new NotificationMessage(NotificationType.SessionReminder, "Your session is soon",
            $"This is a reminder for {BookingMapper.Describe(booking)}. Please arrive 10 minutes early."));
    }

    private async Task<int> CalculatePointsAsync(Booking booking)
    {
        var settings = await _db.SystemSettings.AsNoTracking().OrderBy(s => s.Id).FirstAsync();
        return settings.PointsPerPlayer * booking.PlayerCount + (int)Math.Floor(booking.TotalPrice * settings.PointsPerCurrencyUnit);
    }

    private static NotificationMessage? StatusMessage(Booking booking, BookingStatusEnum status, string? reason)
    {
        var suffix = string.IsNullOrWhiteSpace(reason) ? string.Empty : $" Reason: {reason}";
        return status switch
        {
            BookingStatusEnum.Confirmed => new(NotificationType.BookingConfirmed, "Booking confirmed",
                $"Your booking for {BookingMapper.Describe(booking)} is confirmed."),
            BookingStatusEnum.Rejected => new(NotificationType.BookingRejected, "Booking rejected",
                $"We could not accept your booking for {BookingMapper.Describe(booking)}.{suffix}"),
            BookingStatusEnum.Cancelled => new(NotificationType.BookingCancelled, "Booking cancelled",
                $"The booking for {BookingMapper.Describe(booking)} is cancelled.{suffix}"),
            BookingStatusEnum.NoShow => new(NotificationType.BookingNoShow, "Missed session",
                $"We marked the booking for {BookingMapper.Describe(booking)} as a no-show."),
            _ => null
        };
    }

    private async Task<List<ApplicationUser>> StaffForAsync(Booking booking)
    {
        if (booking.Schedule.Room.Manager is { IsActive: true } manager)
            return [manager];
        return await _db.Users.Where(u => u.IsActive).InRoles(_db, Roles.Administrator).ToListAsync();
    }

    private async Task<Booking> LoadAsync(int bookingId) =>
        await _db.Bookings
            .Include(b => b.Client)
            .Include(b => b.Schedule).ThenInclude(s => s.Room).ThenInclude(r => r.Manager)
            .FirstOrDefaultAsync(b => b.Id == bookingId)
        ?? throw new InvalidOperationException($"Booking {bookingId} does not exist.");

    private static string FullName(ApplicationUser user) => $"{user.FirstName} {user.LastName}";
}
