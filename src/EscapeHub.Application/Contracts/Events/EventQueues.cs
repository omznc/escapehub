namespace EscapeHub.Application.Contracts.Events;

public static class EventQueues
{
    public const string BookingCreated = "booking.created";
    public const string BookingStatusChanged = "booking.status-changed";
    public const string BookingCompleted = "booking.completed";
    public const string ResultRecorded = "booking.result-recorded";
    public const string RewardRedeemed = "reward.redeemed";
    public const string SessionReminder = "session.reminder";
    public const string PasswordResetRequested = "password.reset-requested";
    public const string DeadLetter = "escapehub.dead-letter";

    public static readonly string[] All =
    [
        BookingCreated, BookingStatusChanged, BookingCompleted, ResultRecorded,
        RewardRedeemed, SessionReminder, PasswordResetRequested
    ];
}
