using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Identity;

public class SessionValidator
{
    public const string StampClaim = "stamp";
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

    private readonly AppDbContext _db;
    private readonly IMemoryCache _cache;

    public SessionValidator(AppDbContext db, IMemoryCache cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<bool> IsValidAsync(int userId, string? stamp)
    {
        var current = await _cache.GetOrCreateAsync(CacheKey(userId), entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;
            return _db.Users.AsNoTracking()
                .Where(u => u.Id == userId && u.IsActive)
                .Select(u => u.SecurityStamp)
                .FirstOrDefaultAsync();
        });
        return current != null && current == stamp;
    }

    public void Invalidate(int userId) => _cache.Remove(CacheKey(userId));

    private static string CacheKey(int userId) => $"session-stamp:{userId}";
}
