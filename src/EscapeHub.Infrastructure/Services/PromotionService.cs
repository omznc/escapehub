using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Promotions;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class PromotionService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;
    private readonly ILogger<PromotionService> _logger;

    public PromotionService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BusinessClock clock, ILogger<PromotionService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _clock = clock;
        _logger = logger;
    }

    public async Task<PagedResult<PromotionDto>> GetAllAsync(PromotionQuery query)
    {
        var now = _clock.Now;
        var today = now.Date;
        var promotions = _access.VisiblePromotions().AsNoTracking();
        if (query.Search.Like() is { } like)
            promotions = promotions.Where(p => EF.Functions.Like(p.Name, like) || EF.Functions.Like(p.Description, like));
        if (query.IsActive.HasValue) promotions = promotions.Where(p => p.IsActive == query.IsActive);
        if (query.RoomId.HasValue) promotions = promotions.Where(p => !p.Rooms.Any() || p.Rooms.Any(r => r.Id == query.RoomId));
        if (query.CurrentlyValid.HasValue)
            promotions = promotions.Where(query.CurrentlyValid.Value ? IsValidOn(today) : IsValidOn(today).Not());

        var sorted = query.IsNewestFirst() ? promotions.NewestFirst() : promotions.OrderByDescending(p => p.StartDate).ThenBy(p => p.Name);
        var page = await sorted
            .Select(Project(now))
            .ToPagedResultAsync(query);
        page.Items.ForEach(ApplyVisibility);
        return page;
    }

    public async Task<PagedResult<PromotionDto>> GetActiveAsync(ActivePromotionQuery query)
    {
        var now = _clock.Now;
        var today = now.Date;
        var promotions = _db.Promotions.AsNoTracking().Where(p => !p.IsDeleted).Where(IsValidOn(today));
        if (query.RoomId.HasValue) promotions = promotions.Where(p => !p.Rooms.Any() || p.Rooms.Any(r => r.Id == query.RoomId));
        if (query.Search.Like() is { } like) promotions = promotions.Where(p => EF.Functions.Like(p.Name, like));

        var page = await promotions.OrderBy(p => p.EndDate).ThenBy(p => p.Name).Select(Project(now)).ToPagedResultAsync(query);
        page.Items.ForEach(ApplyVisibility);
        return page;
    }

    public async Task<PromotionDto> GetByIdAsync(int id)
    {
        var promotion = await _access.VisiblePromotions().AsNoTracking()
            .Where(p => p.Id == id)
            .Select(Project(_clock.Now))
            .FirstOrDefaultAsync()
            ?? throw new NotFoundException("Promotion not found.");
        ApplyVisibility(promotion);
        return promotion;
    }

    public async Task<PromotionDto> CreateAsync(SavePromotionRequest request)
    {
        var rooms = await ValidateAsync(request);
        var promotion = new Promotion();
        Apply(promotion, request, rooms);
        _db.Promotions.Add(promotion);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Promotion {PromotionId} created by {UserId}", promotion.Id, _currentUser.Id);
        return await GetByIdAsync(promotion.Id);
    }

    public async Task<PromotionDto> UpdateAsync(int id, SavePromotionRequest request)
    {
        var promotion = await LoadManagedAsync(id);
        var rooms = await ValidateAsync(request);
        promotion.Rooms.Clear();
        Apply(promotion, request, rooms);
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task SetActiveAsync(int id, bool isActive)
    {
        var promotion = await LoadManagedAsync(id);
        promotion.IsActive = isActive;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Promotion {PromotionId} active state set to {IsActive} by {UserId}", id, isActive, _currentUser.Id);
    }

    public async Task DeleteAsync(int id)
    {
        var promotion = await LoadManagedAsync(id);
        var upcoming = await _db.Bookings.Where(b => b.PromotionId == id).CountAsync(BookingRules.IsUpcoming(_clock.Now));
        if (upcoming > 0)
            throw new ConflictException($"This promotion is used by {upcoming.Counted("upcoming booking", "upcoming bookings")} and cannot be deleted. Deactivate it instead.");

        promotion.IsDeleted = true;
        promotion.IsActive = false;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Promotion {PromotionId} deleted by {UserId}", id, _currentUser.Id);
    }

    private async Task<Promotion> LoadManagedAsync(int id)
    {
        var promotion = await _db.Promotions.Include(p => p.Rooms).FirstOrDefaultAsync(p => p.Id == id && !p.IsDeleted)
            ?? throw new NotFoundException("Promotion not found.");
        if (_currentUser.IsManager && (promotion.Rooms.Count == 0 || promotion.Rooms.Any(r => r.ManagerId != _currentUser.Id)))
            throw new ForbiddenException("You can manage only the promotions for your own rooms.");
        return promotion;
    }

    private async Task<List<Room>> ValidateAsync(SavePromotionRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        var type = await _db.PromotionTypes.AsNoTracking().FirstOrDefaultAsync(t => t.Id == request.PromotionTypeId);
        if (type == null)
            errors["promotionTypeId"] = ["Select a promotion type from the list."];
        else if (type.IsPercentage && request.DiscountValue > 100)
            errors["discountValue"] = ["A percentage discount cannot be more than 100."];
        if (request.EndDate < request.StartDate)
            errors["endDate"] = ["End date must be on or after the start date."];

        var roomIds = request.RoomIds.Distinct().ToList();
        var rooms = await _db.Rooms.Where(r => roomIds.Contains(r.Id)).ToListAsync();
        if (rooms.Count != roomIds.Count)
            errors["roomIds"] = ["Select rooms from the list."];
        else if (_currentUser.IsManager && (rooms.Count == 0 || rooms.Any(r => r.ManagerId != _currentUser.Id)))
            errors["roomIds"] = ["Select one or more of your own rooms."];

        if (errors.Count > 0)
            throw new BusinessException(errors.First().Value[0], errors);
        return rooms;
    }

    private static void Apply(Promotion promotion, SavePromotionRequest request, List<Room> rooms)
    {
        promotion.Name = request.Name.Trim();
        promotion.Description = request.Description.Trim();
        promotion.PromotionTypeId = request.PromotionTypeId;
        promotion.DiscountValue = request.DiscountValue;
        promotion.StartDate = request.StartDate!.Value.Date;
        promotion.EndDate = request.EndDate!.Value.Date;
        promotion.IsActive = request.IsActive;
        rooms.ForEach(promotion.Rooms.Add);
    }

    private static Expression<Func<Promotion, bool>> IsValidOn(DateTime day) =>
        p => p.IsActive && p.StartDate <= day && p.EndDate >= day;

    private static Expression<Func<Promotion, PromotionDto>> Project(DateTime now)
    {
        var today = now.Date;
        var upcoming = BookingRules.IsUpcoming(now);
        return p => new PromotionDto
        {
            Id = p.Id,
            Name = p.Name,
            Description = p.Description,
            PromotionTypeId = p.PromotionTypeId,
            PromotionTypeName = p.PromotionType.Name,
            IsPercentage = p.PromotionType.IsPercentage,
            DiscountValue = p.DiscountValue,
            StartDate = p.StartDate,
            EndDate = p.EndDate,
            IsActive = p.IsActive,
            IsCurrentlyValid = p.IsActive && p.StartDate <= today && p.EndDate >= today,
            AppliesToAllRooms = !p.Rooms.Any(),
            Rooms = p.Rooms.OrderBy(r => r.Name).Select(r => new PromotionRoomDto { Id = r.Id, Name = r.Name }).ToList(),
            BookingCount = p.Bookings.Count(),
            CanDelete = !p.Bookings.AsQueryable().Any(upcoming)
        };
    }

    private void ApplyVisibility(PromotionDto promotion)
    {
        if (_currentUser.IsClient)
        {
            promotion.BookingCount = null;
            promotion.CanDelete = null;
            return;
        }
        if (promotion.CanDelete == false)
            promotion.DeleteBlockedReason = "This promotion is used by upcoming bookings and cannot be deleted. Deactivate it instead.";
    }
}
