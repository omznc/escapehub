using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Worker.Email;

namespace EscapeHub.Worker.Handlers;

public class AccountEventHandler
{
    private readonly AppDbContext _db;
    private readonly Notifier _notifier;
    private readonly EmailSender _email;

    public AccountEventHandler(AppDbContext db, Notifier notifier, EmailSender email)
    {
        _db = db;
        _notifier = notifier;
        _email = email;
    }

    public async Task HandleAsync(RewardRedeemedEvent message)
    {
        var redemption = await _db.RewardRedemptions
            .Include(r => r.Client)
            .Include(r => r.LoyaltyReward)
            .FirstOrDefaultAsync(r => r.Id == message.RedemptionId)
            ?? throw new InvalidOperationException($"Redemption {message.RedemptionId} does not exist.");

        await _notifier.NotifyAsync(redemption.Client, new NotificationMessage(NotificationType.RewardRedeemed, "Reward redeemed",
            $"You redeemed {redemption.LoyaltyReward.Name} for {redemption.PointsSpent} points. " +
            $"Your voucher code is {redemption.Code}. Enter it when you book a session."));
    }

    public async Task HandleAsync(PasswordResetRequestedEvent message)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == message.UserId)
            ?? throw new InvalidOperationException($"User {message.UserId} does not exist.");

        await _email.SendAsync(message.Email, $"{user.FirstName} {user.LastName}", "Your EscapeHub password reset code",
            $"Hello {user.FirstName},\n\nYour password reset code is {message.Code}. " +
            $"The code expires in {message.ExpiresInMinutes} minutes.\n\n" +
            "If you did not ask for a new password, ignore this email.\n\nEscapeHub");
    }
}
