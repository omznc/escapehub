using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using EscapeHub.Application.DTOs.Settings;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class SettingsService
{
    private const string CacheKey = "system-settings";

    private readonly AppDbContext _db;
    private readonly IMemoryCache _cache;
    private readonly ICurrentUser _currentUser;

    public SettingsService(AppDbContext db, IMemoryCache cache, ICurrentUser currentUser)
    {
        _db = db;
        _cache = cache;
        _currentUser = currentUser;
    }

    public async Task<SettingsDto> GetAsync()
    {
        return await _cache.GetOrCreateAsync(CacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            return await _db.SystemSettings.AsNoTracking()
                .OrderBy(s => s.Id)
                .Select(s => new SettingsDto
                {
                    CompanyName = s.CompanyName,
                    ContactEmail = s.ContactEmail,
                    ContactPhone = s.ContactPhone,
                    PointsPerPlayer = s.PointsPerPlayer,
                    PointsPerCurrencyUnit = s.PointsPerCurrencyUnit,
                    CancellationDeadlineHours = s.CancellationDeadlineHours,
                    ReminderHoursBefore = s.ReminderHoursBefore,
                    UpdatedAt = s.UpdatedAt,
                    UpdatedByName = s.UpdatedBy != null ? s.UpdatedBy.FirstName + " " + s.UpdatedBy.LastName : null
                })
                .FirstOrDefaultAsync() ?? throw new NotFoundException("System settings are not configured.");
        }) ?? throw new NotFoundException("System settings are not configured.");
    }

    public async Task<SettingsDto> UpdateAsync(UpdateSettingsRequest request)
    {
        var settings = await _db.SystemSettings.OrderBy(s => s.Id).FirstOrDefaultAsync()
            ?? throw new NotFoundException("System settings are not configured.");

        settings.CompanyName = request.CompanyName.Trim();
        settings.ContactEmail = request.ContactEmail.Trim();
        settings.ContactPhone = request.ContactPhone;
        settings.PointsPerPlayer = request.PointsPerPlayer;
        settings.PointsPerCurrencyUnit = request.PointsPerCurrencyUnit;
        settings.CancellationDeadlineHours = request.CancellationDeadlineHours;
        settings.ReminderHoursBefore = request.ReminderHoursBefore;
        settings.UpdatedById = _currentUser.Id;
        await _db.SaveChangesAsync();

        _cache.Remove(CacheKey);
        return await GetAsync();
    }
}
