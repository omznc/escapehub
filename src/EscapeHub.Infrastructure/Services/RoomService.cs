using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Rooms;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Infrastructure.Services;

public class RoomService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;
    private readonly ILogger<RoomService> _logger;

    public RoomService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BusinessClock clock, ILogger<RoomService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _clock = clock;
        _logger = logger;
    }

    public async Task<PagedResult<RoomListItemDto>> GetAllAsync(RoomQuery query)
    {
        var rooms = ApplyFilters(VisibleRooms(query), query);
        var sorted = query.SortBy == RoomSortOptions.Newest
            ? rooms.NewestFirst().Select(Project<RoomListItemDto>())
            : Sort(rooms.Select(Project<RoomListItemDto>()), query.SortBy);
        var page = await sorted.ToPagedResultAsync(query);
        page.Items.ForEach(ApplyVisibility);
        return page;
    }

    public async Task<RoomDto> GetByIdAsync(int id)
    {
        var visible = _currentUser.IsClient ? _db.Rooms.Where(r => r.IsActive) : _access.ManagedRooms();
        var rooms = visible.AsNoTracking().Where(r => r.Id == id);
        var room = await rooms.Select(Project<RoomDto>()).FirstOrDefaultAsync()
            ?? throw new NotFoundException("Room not found.");

        var details = await rooms.Select(r => new
        {
            r.LongDescription,
            r.AgeRecommendation,
            Scenarios = r.Scenarios.Where(s => s.IsActive && !s.IsDeleted).OrderBy(s => s.Name).Select(s => new RoomScenarioSummaryDto
            {
                Id = s.Id,
                Name = s.Name,
                Story = s.Story,
                DifficultyName = s.DifficultyOverride != null ? s.DifficultyOverride.Name : r.DifficultyLevel.Name,
                HintPolicy = s.HintPolicy
            }).ToList()
        }).FirstAsync();

        room.LongDescription = details.LongDescription;
        room.AgeRecommendation = details.AgeRecommendation;
        room.Scenarios = details.Scenarios;
        ApplyVisibility(room);
        return room;
    }

    public async Task<RoomStatsDto> GetStatsAsync(int id, DateTime? from, DateTime? to)
    {
        await _access.EnsureCanManageRoomAsync(id);

        var end = (to ?? _clock.Today).Date;
        var start = (from ?? end.AddDays(-90)).Date;
        if (start > end)
            throw new BusinessException("The start date must be on or before the end date.", "from");
        var bookings = await _db.Bookings.AsNoTracking()
            .Where(b => b.Schedule.RoomId == id && b.Schedule.Date >= start && b.Schedule.Date <= end)
            .GroupBy(_ => 1)
            .OrderBy(g => g.Key)
            .Select(g => new
            {
                Total = g.Count(),
                Completed = g.Count(b => b.BookingStatusId == BookingRules.Completed),
                Cancelled = g.Count(b => b.BookingStatusId == BookingRules.Cancelled),
                Revenue = g.Where(b => b.BookingStatusId == BookingRules.Completed).Sum(b => (decimal?)b.TotalPrice) ?? 0,
                Results = g.Count(b => b.RoomResult != null),
                Escaped = g.Count(b => b.RoomResult != null && b.RoomResult.Escaped),
                AverageMinutes = g.Average(b => (double?)b.RoomResult!.CompletionTimeMinutes)
            })
            .FirstOrDefaultAsync();

        var slots = (await OccupancyQuery.ByRoomAsync(_db, start, end, null, id)).FirstOrDefault();

        var reviews = await _db.Reviews.AsNoTracking()
            .Where(r => r.RoomId == id && !r.IsHidden)
            .GroupBy(_ => 1)
            .OrderBy(g => g.Key)
            .Select(g => new { Count = g.Count(), Average = g.Average(r => (double)r.Rating) })
            .FirstOrDefaultAsync();

        return new RoomStatsDto
        {
            RoomId = id,
            From = start,
            To = end,
            TotalBookings = bookings?.Total ?? 0,
            CompletedBookings = bookings?.Completed ?? 0,
            CancelledBookings = bookings?.Cancelled ?? 0,
            Revenue = bookings?.Revenue ?? 0,
            AverageRating = Math.Round(reviews?.Average ?? 0, 2),
            ReviewCount = reviews?.Count ?? 0,
            TotalSlots = slots?.TotalSlots ?? 0,
            BookedSlots = slots?.BookedSlots ?? 0,
            OccupancyPercent = slots?.Percent ?? 0,
            RecordedResults = bookings?.Results ?? 0,
            EscapeRatePercent = OccupancyQuery.Percent(bookings?.Escaped ?? 0, bookings?.Results ?? 0),
            AverageCompletionMinutes = bookings?.AverageMinutes is { } minutes ? Math.Round(minutes, 1) : null
        };
    }

    public async Task<RoomDto> CreateAsync(SaveRoomRequest request)
    {
        await ValidateAsync(request, null);
        var room = new Room();
        Apply(room, request);
        room.ManagerId = _currentUser.IsManager ? _currentUser.Id : request.ManagerId;
        _db.Rooms.Add(room);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Room {RoomId} created by {UserId}", room.Id, _currentUser.Id);
        return await GetByIdAsync(room.Id);
    }

    public async Task<RoomDto> UpdateAsync(int id, SaveRoomRequest request)
    {
        var room = await _access.GetManagedRoomAsync(id);
        await ValidateAsync(request, id);
        Apply(room, request);
        if (_currentUser.IsAdmin)
            room.ManagerId = request.ManagerId;
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task SetActiveAsync(int id, bool isActive)
    {
        var room = await _access.GetManagedRoomAsync(id);
        room.IsActive = isActive;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Room {RoomId} active state set to {IsActive} by {UserId}", id, isActive, _currentUser.Id);
    }

    public async Task DeleteAsync(int id)
    {
        var room = await _access.GetManagedRoomAsync(id);
        var bookingCount = await _db.Bookings.CountAsync(b => b.Schedule.RoomId == id);
        var reviewCount = await _db.Reviews.CountAsync(r => r.RoomId == id);
        if (bookingCount > 0 || reviewCount > 0)
            throw new ConflictException(DeleteReason(bookingCount, reviewCount));

        var promotions = await _db.Promotions.Include(p => p.Rooms).Where(p => p.Rooms.Any(r => r.Id == id)).ToListAsync();
        foreach (var promotion in promotions)
        {
            promotion.Rooms.Remove(room);
            if (promotion.Rooms.Count > 0) continue;
            promotion.IsDeleted = true;
            promotion.IsActive = false;
        }

        room.IsDeleted = true;
        room.IsActive = false;
        await using var transaction = await _db.Database.BeginTransactionAsync();
        await _db.Schedules.Where(s => s.RoomId == id).ExecuteDeleteAsync();
        await _db.RoomScenarios.Where(s => s.RoomId == id).ExecuteUpdateAsync(s => s.SetProperty(x => x.IsDeleted, true));
        await _db.SaveChangesAsync();
        await transaction.CommitAsync();
        _logger.LogInformation("Room {RoomId} deleted by {UserId}", id, _currentUser.Id);
    }

    private static Expression<Func<Room, T>> Project<T>() where T : RoomListItemDto, new()
    {
        var active = BookingRules.IsActive;
        return r => new T
        {
            Id = r.Id,
            Name = r.Name,
            ShortDescription = r.ShortDescription,
            ThemeId = r.ThemeId,
            ThemeName = r.Theme.Name,
            DifficultyLevelId = r.DifficultyLevelId,
            DifficultyName = r.DifficultyLevel.Name,
            DifficultyValue = r.DifficultyLevel.Value,
            MinPlayers = r.MinPlayers,
            MaxPlayers = r.MaxPlayers,
            DurationMinutes = r.DurationMinutes,
            PricePerPerson = r.PricePerPerson,
            PricePerBooking = r.PricePerBooking,
            ImageUrl = r.ImageUrl,
            IsActive = r.IsActive,
            CityId = r.CityId,
            CityName = r.City != null ? r.City.Name : null,
            ManagerId = r.ManagerId,
            ManagerName = r.Manager != null ? r.Manager.FirstName + " " + r.Manager.LastName : null,
            AverageRating = Math.Round(r.Reviews.Where(v => !v.IsHidden).Average(v => (double?)v.Rating) ?? 0, 2),
            ReviewCount = r.Reviews.Count(v => !v.IsHidden),
            BookingCount = r.Schedules.SelectMany(s => s.Bookings).AsQueryable().Count(active),
            CanDelete = !r.Schedules.Any(s => s.Bookings.Any()) && !r.Reviews.Any()
        };
    }

    private IQueryable<Room> VisibleRooms(RoomQuery query)
    {
        if (_currentUser.IsClient)
            return _db.Rooms.AsNoTracking().Where(r => r.IsActive);

        var rooms = _access.ManagedRooms().AsNoTracking();
        if (query.IsActive.HasValue) rooms = rooms.Where(r => r.IsActive == query.IsActive);
        if (query.ManagerId.HasValue) rooms = rooms.Where(r => r.ManagerId == query.ManagerId);
        return rooms;
    }

    private IQueryable<Room> ApplyFilters(IQueryable<Room> rooms, RoomQuery query)
    {
        if (query.Search.Like() is { } like)
            rooms = rooms.Where(r => EF.Functions.Like(r.Name, like) || EF.Functions.Like(r.ShortDescription, like) || EF.Functions.Like(r.Theme.Name, like));
        if (query.ThemeId.HasValue) rooms = rooms.Where(r => r.ThemeId == query.ThemeId);
        if (query.DifficultyLevelId.HasValue) rooms = rooms.Where(r => r.DifficultyLevelId == query.DifficultyLevelId);
        if (query.CityId.HasValue) rooms = rooms.Where(r => r.CityId == query.CityId);
        if (query.AvailableDate.HasValue) rooms = WithOpenSlotOn(rooms, query.AvailableDate.Value.Date);
        return ApplyPlayerAndPriceFilters(rooms, query);
    }

    private static IQueryable<Room> ApplyPlayerAndPriceFilters(IQueryable<Room> rooms, RoomQuery query)
    {
        if (query.MinPlayers.HasValue) rooms = rooms.Where(r => r.MaxPlayers >= query.MinPlayers);
        if (query.MaxPlayers.HasValue) rooms = rooms.Where(r => r.MinPlayers <= query.MaxPlayers);
        if (query.PartySize.HasValue) rooms = rooms.Where(r => r.MinPlayers <= query.PartySize && r.MaxPlayers >= query.PartySize);
        if (query.MinPrice.HasValue) rooms = rooms.Where(r => r.PricePerPerson >= query.MinPrice);
        if (query.MaxPrice.HasValue) rooms = rooms.Where(r => r.PricePerPerson <= query.MaxPrice);
        return rooms;
    }

    private IQueryable<Room> WithOpenSlotOn(IQueryable<Room> rooms, DateTime date)
    {
        var open = BookingRules.IsOpen(_clock.Now);
        return rooms.Where(r => r.Schedules.AsQueryable().Where(s => s.Date == date).Any(open));
    }

    private static IQueryable<RoomListItemDto> Sort(IQueryable<RoomListItemDto> rooms, string? sortBy) => sortBy switch
    {
        RoomSortOptions.Rating => rooms.OrderByDescending(r => r.AverageRating).ThenByDescending(r => r.ReviewCount).ThenBy(r => r.Name),
        RoomSortOptions.Easiest => rooms.OrderBy(r => r.DifficultyValue).ThenBy(r => r.Name),
        RoomSortOptions.Hardest => rooms.OrderByDescending(r => r.DifficultyValue).ThenBy(r => r.Name),
        RoomSortOptions.Cheapest => rooms.OrderBy(r => r.PricePerPerson).ThenBy(r => r.PricePerBooking).ThenBy(r => r.Name),
        RoomSortOptions.Popular => rooms.OrderByDescending(r => r.BookingCount).ThenBy(r => r.Name),
        _ => rooms.OrderBy(r => r.Name)
    };

    private async Task ValidateAsync(SaveRoomRequest request, int? id)
    {
        var errors = new Dictionary<string, string[]>();
        if (request.MaxPlayers < request.MinPlayers)
            errors["maxPlayers"] = ["Maximum players must be greater than or equal to minimum players."];
        if (await _db.Rooms.AnyAsync(r => r.Name == request.Name.Trim() && r.Id != id))
            errors["name"] = ["A room with this name already exists."];
        if (!await _db.Themes.AnyAsync(t => t.Id == request.ThemeId))
            errors["themeId"] = ["Select a theme from the list."];
        if (!await _db.DifficultyLevels.AnyAsync(d => d.Id == request.DifficultyLevelId))
            errors["difficultyLevelId"] = ["Select a difficulty level from the list."];
        if (request.CityId.HasValue && !await _db.Cities.AnyAsync(c => c.Id == request.CityId))
            errors["cityId"] = ["Select a city from the list."];
        if (_currentUser.IsAdmin && request.ManagerId.HasValue &&
            !await _db.Users.Where(u => u.Id == request.ManagerId && u.IsActive).InRoles(_db, Roles.RoomManager).AnyAsync())
            errors["managerId"] = ["Select an active room manager from the list."];

        if (errors.Count > 0)
            throw new BusinessException(errors.First().Value[0], errors);
    }

    private static void Apply(Room room, SaveRoomRequest request)
    {
        room.Name = request.Name.Trim();
        room.ShortDescription = request.ShortDescription.Trim();
        room.LongDescription = request.LongDescription.Trim();
        room.ThemeId = request.ThemeId;
        room.DifficultyLevelId = request.DifficultyLevelId;
        room.MinPlayers = request.MinPlayers;
        room.MaxPlayers = request.MaxPlayers;
        room.DurationMinutes = request.DurationMinutes;
        room.PricePerPerson = request.PricePerPerson;
        room.PricePerBooking = request.PricePerBooking;
        room.IsActive = request.IsActive;
        room.AgeRecommendation = request.AgeRecommendation;
        room.CityId = request.CityId;
    }

    private void ApplyVisibility(RoomListItemDto room)
    {
        if (_currentUser.IsClient)
        {
            room.ManagerId = null;
            room.ManagerName = null;
            room.BookingCount = null;
            room.CanDelete = null;
            return;
        }
        if (room.CanDelete == false)
            room.DeleteBlockedReason = "This room has bookings or reviews and cannot be deleted. Archive it instead.";
    }

    private static string DeleteReason(int bookings, int reviews)
    {
        var usage = new[] { (bookings, "booking", "bookings"), (reviews, "review", "reviews") }
            .Where(u => u.Item1 > 0)
            .Select(u => u.Item1.Counted(u.Item2, u.Item3));
        return $"This room has {string.Join(" and ", usage)} and cannot be deleted. Archive it instead.";
    }
}
