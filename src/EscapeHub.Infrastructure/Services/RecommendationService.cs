using System.Globalization;
using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Recommendations;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class RecommendationService
{
    private const int PopularityDays = 90;
    private const double ThemeWeight = 0.35;
    private const double DifficultyWeight = 0.20;
    private const double GroupWeight = 0.10;
    private const double PopularityWeight = 0.15;
    private const double RatingWeight = 0.20;
    private const double PlayedPenalty = 0.5;
    private const double PriorRating = 3.5;
    private const int PriorReviews = 2;
    private const double PopularThreshold = 0.9;

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public RecommendationService(AppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<PagedResult<RecommendationDto>> GetForCurrentUserAsync(RecommendationQuery query)
    {
        var profile = await LoadProfileAsync(_currentUser.Id);
        var rooms = await LoadRoomsAsync();
        var maxPopularity = Math.Max(1, rooms.Count == 0 ? 0 : rooms.Max(r => r.RecentBookings));

        var ranked = rooms
            .Select(room => Score(room, profile, maxPopularity))
            .OrderBy(r => r.AlreadyPlayed)
            .ThenByDescending(r => r.Score)
            .ThenBy(r => r.RoomId)
            .ToList();
        return new PagedResult<RecommendationDto>
        {
            Items = ranked.Skip((query.Page - 1) * query.PageSize).Take(query.PageSize).ToList(),
            TotalCount = ranked.Count,
            Page = query.Page,
            PageSize = query.PageSize
        };
    }

    private async Task<ClientProfile> LoadProfileAsync(int clientId)
    {
        var sessions = await _db.Bookings.AsNoTracking()
            .Where(b => b.ClientId == clientId && b.BookingStatusId == BookingRules.Completed)
            .Select(b => new PlayedSession(b.Schedule.RoomId, b.Schedule.Room.ThemeId, b.Schedule.Room.DifficultyLevel.Value, b.PlayerCount))
            .ToListAsync();
        var ratings = await _db.Reviews.AsNoTracking()
            .Where(r => r.ClientId == clientId)
            .ToDictionaryAsync(r => r.RoomId, r => r.Rating);
        return ClientProfile.Build(sessions, ratings);
    }

    private async Task<List<RoomCandidate>> LoadRoomsAsync()
    {
        var since = DateTime.UtcNow.Date.AddDays(-PopularityDays);
        var active = BookingRules.IsActive;
        return await _db.Rooms.AsNoTracking()
            .Where(r => r.IsActive)
            .Select(r => new RoomCandidate
            {
                RoomId = r.Id,
                Name = r.Name,
                ShortDescription = r.ShortDescription,
                ImageUrl = r.ImageUrl,
                ThemeId = r.ThemeId,
                ThemeName = r.Theme.Name,
                DifficultyName = r.DifficultyLevel.Name,
                DifficultyValue = r.DifficultyLevel.Value,
                MinPlayers = r.MinPlayers,
                MaxPlayers = r.MaxPlayers,
                DurationMinutes = r.DurationMinutes,
                PricePerPerson = r.PricePerPerson,
                PricePerBooking = r.PricePerBooking,
                AverageRating = r.Reviews.Where(v => !v.IsHidden).Average(v => (double?)v.Rating) ?? 0,
                ReviewCount = r.Reviews.Count(v => !v.IsHidden),
                RecentBookings = r.Schedules.SelectMany(s => s.Bookings).AsQueryable()
                    .Where(active)
                    .Count(b => b.CreatedAt >= since)
            })
            .ToListAsync();
    }

    private static RecommendationDto Score(RoomCandidate room, ClientProfile profile, int maxPopularity)
    {
        var theme = profile.ThemeAffinity(room.ThemeId);
        var difficulty = profile.DifficultyMatch(room.DifficultyValue);
        var group = profile.GroupFits(room.MinPlayers, room.MaxPlayers);
        var popularity = (double)room.RecentBookings / maxPopularity;
        var rating = SmoothedRating(room) / 5;
        var played = profile.PlayedRooms.Contains(room.RoomId);

        var score = ThemeWeight * theme + DifficultyWeight * difficulty + GroupWeight * group +
                    PopularityWeight * popularity + RatingWeight * rating;
        if (played) score *= PlayedPenalty;

        return new RecommendationDto
        {
            RoomId = room.RoomId,
            Name = room.Name,
            ShortDescription = room.ShortDescription,
            ImageUrl = room.ImageUrl,
            ThemeName = room.ThemeName,
            DifficultyName = room.DifficultyName,
            MinPlayers = room.MinPlayers,
            MaxPlayers = room.MaxPlayers,
            DurationMinutes = room.DurationMinutes,
            PricePerPerson = room.PricePerPerson,
            PricePerBooking = room.PricePerBooking,
            AverageRating = Math.Round(room.AverageRating, 2),
            ReviewCount = room.ReviewCount,
            Score = Math.Round(score * 100, 1),
            AlreadyPlayed = played,
            Reason = Explain(room, profile, theme, difficulty, group, popularity, played)
        };
    }

    private static double SmoothedRating(RoomCandidate room) =>
        (room.AverageRating * room.ReviewCount + PriorRating * PriorReviews) / (room.ReviewCount + PriorReviews);

    private static string Explain(RoomCandidate room, ClientProfile profile, double theme, double difficulty, double group, double popularity, bool played)
    {
        var parts = new List<string>();
        if (played) parts.Add("You played this room before, but it still matches your taste");
        if (LikedReason(room, theme, difficulty) is { } liked) parts.Add(liked);
        if (group > 0 && profile.TypicalGroupSize is { } size) parts.Add($"Fits your usual group of {size} players");
        if (room.ReviewCount > 0 && room.AverageRating >= 4)
            parts.Add($"Rated {room.AverageRating.ToString("0.0", CultureInfo.InvariantCulture)} out of 5 in {room.ReviewCount.Counted("review", "reviews")}");
        if (popularity >= PopularThreshold) parts.Add("One of the most popular rooms");
        if (parts.Count == 0) parts.Add("A new room for you to try");
        return string.Join(". ", parts) + ".";
    }

    private static string? LikedReason(RoomCandidate room, double theme, double difficulty)
    {
        var liked = new List<string>();
        if (theme >= 0.5) liked.Add(room.ThemeName);
        if (difficulty >= 0.75) liked.Add(room.DifficultyName);
        return liked.Count > 0 ? $"Because you liked {string.Join(" and ", liked)} rooms" : null;
    }

    private record PlayedSession(int RoomId, int ThemeId, int DifficultyValue, int PlayerCount);

    private class ClientProfile
    {
        private const double MaxDifficultyGap = 4;
        private Dictionary<int, double> _themes = new();
        private double? _difficulty;

        public HashSet<int> PlayedRooms { get; private init; } = new();
        public int? TypicalGroupSize { get; private init; }

        public static ClientProfile Build(List<PlayedSession> sessions, Dictionary<int, int> ratings)
        {
            var profile = new ClientProfile
            {
                PlayedRooms = sessions.Select(s => s.RoomId).Concat(ratings.Keys).ToHashSet(),
                TypicalGroupSize = sessions.Count == 0 ? null : Median(sessions.Select(s => s.PlayerCount))
            };
            var weighted = sessions.Select(s => (Session: s, Weight: SessionWeight(ratings.GetValueOrDefault(s.RoomId)))).ToList();
            profile._themes = weighted.GroupBy(w => w.Session.ThemeId).ToDictionary(g => g.Key, g => g.Sum(w => w.Weight));
            var positive = weighted.Where(w => w.Weight > 0).ToList();
            if (positive.Count > 0)
                profile._difficulty = positive.Sum(w => w.Session.DifficultyValue * w.Weight) / positive.Sum(w => w.Weight);
            return profile;
        }

        public double ThemeAffinity(int themeId)
        {
            var best = _themes.Values.DefaultIfEmpty(0).Max();
            return best <= 0 ? 0 : Math.Max(0, _themes.GetValueOrDefault(themeId)) / best;
        }

        public double DifficultyMatch(int value) =>
            _difficulty is { } preferred ? Math.Max(0, 1 - Math.Abs(value - preferred) / MaxDifficultyGap) : 0;

        public double GroupFits(int min, int max) =>
            TypicalGroupSize is { } size && size >= min && size <= max ? 1 : 0;

        private static double SessionWeight(int rating) => rating switch
        {
            0 => 1,
            >= 4 => 1 + (rating - 3) * 0.5,
            3 => 0.5,
            _ => -1
        };

        private static int Median(IEnumerable<int> values)
        {
            var sorted = values.Order().ToList();
            return sorted[sorted.Count / 2];
        }
    }

    private class RoomCandidate
    {
        public int RoomId { get; init; }
        public string Name { get; init; } = string.Empty;
        public string ShortDescription { get; init; } = string.Empty;
        public string? ImageUrl { get; init; }
        public int ThemeId { get; init; }
        public string ThemeName { get; init; } = string.Empty;
        public string DifficultyName { get; init; } = string.Empty;
        public int DifficultyValue { get; init; }
        public int MinPlayers { get; init; }
        public int MaxPlayers { get; init; }
        public int DurationMinutes { get; init; }
        public decimal PricePerPerson { get; init; }
        public decimal PricePerBooking { get; init; }
        public double AverageRating { get; init; }
        public int ReviewCount { get; init; }
        public int RecentBookings { get; init; }
    }
}
