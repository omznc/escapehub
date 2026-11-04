namespace EscapeHub.Application.Contracts.Events;

public record BookingCreatedEvent(int BookingId, int ClientId);

public record BookingStatusChangedEvent(int BookingId, int ClientId, int FromStatusId, int ToStatusId, string? Reason, int ChangedById);

public record BookingCompletedEvent(int BookingId, int ClientId);

public record ResultRecordedEvent(int BookingId, int ClientId);

public record RewardRedeemedEvent(int RedemptionId, int ClientId);

public record SessionReminderEvent(int BookingId, int ClientId);

public record PasswordResetRequestedEvent(int UserId, string Email, string Code, int ExpiresInMinutes)
{
    public override string ToString() => $"{nameof(PasswordResetRequestedEvent)} {{ UserId = {UserId} }}";
}

public record PaymentCompletedEvent(int BookingId, int ClientId, decimal Amount);

public record PaymentRefundedEvent(int BookingId, int ClientId, decimal Amount);
