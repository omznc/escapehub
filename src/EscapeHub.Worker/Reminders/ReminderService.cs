using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Services;
using EscapeHub.Worker.Configuration;

namespace EscapeHub.Worker.Reminders;

public class ReminderService : BackgroundService
{
    private readonly ReminderOptions _options;
    private readonly IServiceScopeFactory _scopes;
    private readonly IEventPublisher _events;
    private readonly BusinessClock _clock;
    private readonly ILogger<ReminderService> _logger;

    public ReminderService(ReminderOptions options, IServiceScopeFactory scopes, IEventPublisher events, BusinessClock clock,
        ILogger<ReminderService> logger)
    {
        _options = options;
        _scopes = scopes;
        _events = events;
        _clock = clock;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(_options.ScanInterval);
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
                await ScanSafelyAsync(stoppingToken);
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Reminder scan stopped");
        }
    }

    private async Task ScanSafelyAsync(CancellationToken stoppingToken)
    {
        try
        {
            await ScanAsync(stoppingToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "Reminder scan failed. The next scan runs in {Interval}", _options.ScanInterval);
        }
    }

    private async Task ScanAsync(CancellationToken stoppingToken)
    {
        await using var scope = _scopes.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var settings = await db.SystemSettings.AsNoTracking().OrderBy(s => s.Id).FirstOrDefaultAsync(stoppingToken);
        if (settings == null) return;

        var now = _clock.Now;
        var limit = now.AddHours(settings.ReminderHoursBefore);
        var (today, time, limitDay, limitTime) = (now.Date, now.TimeOfDay, limit.Date, limit.TimeOfDay);

        var bookings = await db.Bookings
            .Where(b => b.BookingStatusId == BookingRules.Confirmed && b.ReminderSentAt == null)
            .Where(b => b.Schedule.Date > today || (b.Schedule.Date == today && b.Schedule.StartTime > time))
            .Where(b => b.Schedule.Date < limitDay || (b.Schedule.Date == limitDay && b.Schedule.StartTime <= limitTime))
            .ToListAsync(stoppingToken);
        if (bookings.Count == 0) return;

        var queued = 0;
        foreach (var booking in bookings)
        {
            if (!_events.Publish(EventQueues.SessionReminder, new SessionReminderEvent(booking.Id, booking.ClientId))) continue;
            booking.ReminderSentAt = DateTime.UtcNow;
            queued++;
        }
        await db.SaveChangesAsync(stoppingToken);
        _logger.LogInformation("Queued {Queued} of {Count} session reminders", queued, bookings.Count);
    }
}
