using System.Text.Json;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Worker.Handlers;

namespace EscapeHub.Worker.Messaging;

public class EventDispatcher
{
    private readonly BookingEventHandler _bookings;
    private readonly AccountEventHandler _accounts;

    public EventDispatcher(BookingEventHandler bookings, AccountEventHandler accounts)
    {
        _bookings = bookings;
        _accounts = accounts;
    }

    public Task DispatchAsync(string queue, ReadOnlyMemory<byte> body) => queue switch
    {
        EventQueues.BookingCreated => _bookings.HandleAsync(Read<BookingCreatedEvent>(body)),
        EventQueues.BookingStatusChanged => _bookings.HandleAsync(Read<BookingStatusChangedEvent>(body)),
        EventQueues.BookingCompleted => _bookings.HandleAsync(Read<BookingCompletedEvent>(body)),
        EventQueues.ResultRecorded => _bookings.HandleAsync(Read<ResultRecordedEvent>(body)),
        EventQueues.SessionReminder => _bookings.HandleAsync(Read<SessionReminderEvent>(body)),
        EventQueues.PaymentCompleted => _bookings.HandleAsync(Read<PaymentCompletedEvent>(body)),
        EventQueues.PaymentRefunded => _bookings.HandleAsync(Read<PaymentRefundedEvent>(body)),
        EventQueues.RewardRedeemed => _accounts.HandleAsync(Read<RewardRedeemedEvent>(body)),
        EventQueues.PasswordResetRequested => _accounts.HandleAsync(Read<PasswordResetRequestedEvent>(body)),
        _ => throw new InvalidOperationException($"No handler is registered for queue {queue}.")
    };

    private static T Read<T>(ReadOnlyMemory<byte> body) =>
        JsonSerializer.Deserialize<T>(body.Span, EventSerializer.Options)
        ?? throw new JsonException($"The message body is not a valid {typeof(T).Name}.");
}
