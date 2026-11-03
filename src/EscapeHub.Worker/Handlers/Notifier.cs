using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Worker.Email;

namespace EscapeHub.Worker.Handlers;

public record NotificationMessage(NotificationType Type, string Title, string Text);

public class Notifier
{
    private readonly AppDbContext _db;
    private readonly EmailSender _email;
    private readonly ILogger<Notifier> _logger;

    public Notifier(AppDbContext db, EmailSender email, ILogger<Notifier> logger)
    {
        _db = db;
        _email = email;
        _logger = logger;
    }

    private void Add(ApplicationUser user, NotificationMessage message) =>
        _db.Notifications.Add(new Notification
        {
            UserId = user.Id,
            Type = message.Type,
            Title = message.Title,
            Message = message.Text
        });

    public Task NotifyAsync(ApplicationUser user, params NotificationMessage[] messages) =>
        NotifyAsync(messages.Select(m => (user, m)).ToList());

    public async Task NotifyAsync(List<(ApplicationUser User, NotificationMessage Message)> notifications)
    {
        foreach (var (user, message) in notifications) Add(user, message);
        await _db.SaveChangesAsync();
        foreach (var (user, message) in notifications) await EmailAsync(user, message);
    }

    private async Task EmailAsync(ApplicationUser user, NotificationMessage message)
    {
        try
        {
            await _email.SendAsync(user.Email!, $"{user.FirstName} {user.LastName}", message.Title, $"Hello {user.FirstName},\n\n{message.Text}\n\nEscapeHub");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Email {Type} to user {UserId} failed. The notification is saved in the app.", message.Type, user.Id);
        }
    }
}
