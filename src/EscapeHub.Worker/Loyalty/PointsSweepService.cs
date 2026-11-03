using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Services;
using EscapeHub.Worker.Configuration;
using EscapeHub.Worker.Handlers;

namespace EscapeHub.Worker.Loyalty;

public class PointsSweepService : BackgroundService
{
    private const int BatchSize = 50;
    private static readonly TimeSpan MinimumAge = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan MaximumAge = TimeSpan.FromDays(7);

    private readonly PointsSweepOptions _options;
    private readonly IServiceScopeFactory _scopes;
    private readonly ILogger<PointsSweepService> _logger;

    public PointsSweepService(PointsSweepOptions options, IServiceScopeFactory scopes, ILogger<PointsSweepService> logger)
    {
        _options = options;
        _scopes = scopes;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(_options.Interval);
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
                await SweepSafelyAsync(stoppingToken);
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Points sweep stopped");
        }
    }

    private async Task SweepSafelyAsync(CancellationToken stoppingToken)
    {
        try
        {
            await SweepAsync(stoppingToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "Points sweep failed. The next sweep runs in {Interval}", _options.Interval);
        }
    }

    private async Task SweepAsync(CancellationToken stoppingToken)
    {
        var missing = await FindMissingAsync(stoppingToken);
        foreach (var message in missing)
        {
            _logger.LogWarning("Booking {BookingId} is completed but has no points. Awarding them now", message.BookingId);
            await AwardAsync(message);
        }
    }

    private async Task AwardAsync(BookingCompletedEvent message)
    {
        try
        {
            await using var scope = _scopes.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<BookingEventHandler>().HandleAsync(message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Points sweep could not award points for booking {BookingId}", message.BookingId);
        }
    }

    private async Task<List<BookingCompletedEvent>> FindMissingAsync(CancellationToken stoppingToken)
    {
        await using var scope = _scopes.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now = DateTime.UtcNow;
        var (oldest, newest) = (now - MaximumAge, now - MinimumAge);

        return await db.Bookings.AsNoTracking()
            .Where(b => b.BookingStatusId == BookingRules.Completed &&
                        !b.LoyaltyTransactions.Any(t => t.TransactionType == TransactionType.Earned))
            .Where(b => b.StatusHistory.Any(h => h.ToStatusId == BookingRules.Completed && h.CreatedAt >= oldest && h.CreatedAt <= newest))
            .OrderBy(b => b.Id)
            .Take(BatchSize)
            .Select(b => new BookingCompletedEvent(b.Id, b.ClientId))
            .ToListAsync(stoppingToken);
    }
}
