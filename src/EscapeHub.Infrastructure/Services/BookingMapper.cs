using System.Globalization;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;

namespace EscapeHub.Infrastructure.Services;

public static class BookingMapper
{
    public static string FormatTime(TimeSpan time) => time.ToString(@"hh\:mm");

    public static string Describe(Booking booking) =>
        $"{booking.Schedule.Room.Name} on {booking.Schedule.Date.ToString("dd.MM.yyyy", CultureInfo.InvariantCulture)} at {FormatTime(booking.Schedule.StartTime)}";

    public static BookingDto ToDto(Booking b, ICurrentUser user, int cancellationDeadlineHours, bool hasReview, DateTime now)
    {
        var (canCancel, cancelReason) = CancelState(b, user, cancellationDeadlineHours, now);
        var status = BookingStateMachine.StatusOf(b);
        var payment = b.Payments.MaxBy(p => p.Id);
        var paid = b.Payments.FirstOrDefault(p => p.Status == PaymentStatus.Succeeded);
        var payProblem = PaymentRules.Problem(b, now);
        return new BookingDto
        {
            Id = b.Id,
            RoomId = b.Schedule.RoomId,
            RoomName = b.Schedule.Room.Name,
            RoomImageUrl = b.Schedule.Room.ImageUrl,
            ThemeName = b.Schedule.Room.Theme.Name,
            ScheduleId = b.ScheduleId,
            Date = b.Schedule.Date,
            StartTime = FormatTime(b.Schedule.StartTime),
            EndTime = FormatTime(b.Schedule.EndTime),
            ClientId = b.ClientId,
            ClientName = $"{b.Client.FirstName} {b.Client.LastName}",
            ClientPictureUrl = b.Client.ProfilePictureUrl,
            ClientEmail = b.Client.Email!,
            StatusId = b.BookingStatusId,
            Status = b.BookingStatus.Name,
            PlayerCount = b.PlayerCount,
            Subtotal = b.Subtotal,
            DiscountApplied = b.DiscountApplied,
            TotalPrice = b.TotalPrice,
            PromotionId = b.PromotionId,
            PromotionName = b.Promotion?.Name,
            RedemptionId = b.RewardRedemption?.Id,
            VoucherCode = b.RewardRedemption?.Code,
            RewardName = b.RewardRedemption?.LoyaltyReward.Name,
            Notes = b.Notes,
            ParticipantNames = b.BookingMembers.OrderBy(m => m.Id).Select(m => m.ParticipantName).ToList(),
            HasResult = b.RoomResult != null,
            IsPaid = paid != null,
            PaymentStatus = payment?.Status.ToString(),
            PaidAt = paid?.PaidAt,
            PaidAmount = paid?.Amount,
            CanPay = user.IsClient && payProblem == null,
            PayBlockedReason = user.IsClient ? payProblem : null,
            Result = b.RoomResult == null ? null : new RoomResultDto
            {
                Escaped = b.RoomResult.Escaped,
                CompletionTimeMinutes = b.RoomResult.CompletionTimeMinutes,
                HintsUsed = b.RoomResult.HintsUsed,
                ManagerNotes = b.RoomResult.ManagerNotes,
                Score = b.RoomResult.Score,
                RecordedByName = $"{b.RoomResult.RecordedBy.FirstName} {b.RoomResult.RecordedBy.LastName}",
                RecordedAt = b.RoomResult.CreatedAt
            },
            PointsEarned = b.LoyaltyTransactions.Where(t => t.TransactionType == TransactionType.Earned).Sum(t => t.Points),
            CanCancel = canCancel,
            CancelBlockedReason = cancelReason,
            CanReview = user.IsClient && status == BookingStatusEnum.Completed && !hasReview,
            AllowedActions = user.IsClient ? [] : StaffActions(b, status, now),
            BlockedReasons = user.IsClient ? new() : BlockedReasons(b, now),
            StatusHistory = b.StatusHistory.OrderBy(h => h.CreatedAt).ThenBy(h => h.Id).Select(h => new BookingStatusHistoryDto
            {
                FromStatus = h.FromStatus?.Name,
                ToStatus = h.ToStatus.Name,
                ChangedByName = h.ChangedBy == null ? null : $"{h.ChangedBy.FirstName} {h.ChangedBy.LastName}",
                Reason = h.Reason,
                ChangedAt = h.CreatedAt
            }).ToList(),
            CreatedAt = b.CreatedAt
        };
    }

    public static (bool CanCancel, string? Reason) CancelState(Booking booking, ICurrentUser user, int deadlineHours, DateTime now)
    {
        var status = BookingStateMachine.StatusOf(booking);
        if (!BookingStateMachine.CanMove(status, BookingStatusEnum.Cancelled))
            return (false, $"A {BookingStateMachine.Describe(status)} booking cannot be cancelled.");
        if (user.IsClient && booking.Payments.Any(p => p.Status == PaymentStatus.Succeeded))
            return (false, "This booking is paid. Contact us to cancel it.");
        if (user.IsClient && booking.Schedule.StartsAt.AddHours(-deadlineHours) <= now)
            return (false, $"Bookings can be cancelled only up to {deadlineHours} hours before the session.");
        return (true, null);
    }

    public static string? BlockedReason(Booking booking, BookingStatusEnum target, DateTime now)
    {
        if (BookingStateMachine.MoveProblem(BookingStateMachine.StatusOf(booking), target) is { } problem)
            return problem;

        var start = booking.Schedule.StartsAt;
        var startText = $"{FormatTime(booking.Schedule.StartTime)} on {booking.Schedule.Date.ToString("dd.MM.yyyy", CultureInfo.InvariantCulture)}";
        return target switch
        {
            BookingStatusEnum.Confirmed when start <= now => "The session has already started. You cannot confirm this booking.",
            BookingStatusEnum.Completed when start > now => $"The session has not started yet. You can complete it after {startText}.",
            BookingStatusEnum.NoShow when start > now => $"The session has not started yet. You can mark it as a no-show after {startText}.",
            _ => null
        };
    }

    private static Dictionary<string, string> BlockedReasons(Booking booking, DateTime now) =>
        StatusActions
            .Select(a => (a.Action, Reason: BlockedReason(booking, a.Target, now)))
            .Where(a => a.Reason != null)
            .ToDictionary(a => a.Action, a => a.Reason!);

    private static List<string> StaffActions(Booking booking, BookingStatusEnum status, DateTime now)
    {
        var actions = StatusActions.Where(a => BlockedReason(booking, a.Target, now) == null).Select(a => a.Action).ToList();
        if (status == BookingStatusEnum.Completed)
            actions.Add(booking.RoomResult == null ? BookingActions.RecordResult : BookingActions.EditResult);
        return actions;
    }

    private static readonly (string Action, BookingStatusEnum Target)[] StatusActions =
    [
        (BookingActions.Confirm, BookingStatusEnum.Confirmed),
        (BookingActions.Reject, BookingStatusEnum.Rejected),
        (BookingActions.Cancel, BookingStatusEnum.Cancelled),
        (BookingActions.Complete, BookingStatusEnum.Completed),
        (BookingActions.NoShow, BookingStatusEnum.NoShow)
    ];
}

public static class BookingActions
{
    public const string Confirm = "confirm";
    public const string Reject = "reject";
    public const string Cancel = "cancel";
    public const string Complete = "complete";
    public const string NoShow = "no-show";
    public const string RecordResult = "record-result";
    public const string EditResult = "edit-result";
}
