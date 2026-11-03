using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Infrastructure.Services;

public class BookingService
{
    private const string UsedVoucherMessage = "This voucher has already been used.";

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly SettingsService _settings;
    private readonly IEventPublisher _events;
    private readonly BusinessClock _clock;
    private readonly ILogger<BookingService> _logger;

    public BookingService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, SettingsService settings,
        IEventPublisher events, BusinessClock clock, ILogger<BookingService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _settings = settings;
        _events = events;
        _clock = clock;
        _logger = logger;
    }

    public Task<PagedResult<BookingListItemDto>> GetAllAsync(BookingQuery query)
    {
        var bookings = _db.Bookings.AsNoTracking();
        if (_access.ManagerScope is { } managerId) bookings = bookings.Where(b => b.Schedule.Room.ManagerId == managerId);
        if (query.StatusId.HasValue) bookings = bookings.Where(b => b.BookingStatusId == query.StatusId);
        if (query.RoomId.HasValue) bookings = bookings.Where(b => b.Schedule.RoomId == query.RoomId);
        if (query.ClientId.HasValue) bookings = bookings.Where(b => b.ClientId == query.ClientId);
        if (query.From.HasValue) bookings = bookings.Where(b => b.Schedule.Date >= query.From.Value.Date);
        if (query.To.HasValue) bookings = bookings.Where(b => b.Schedule.Date <= query.To.Value.Date);
        if (query.Search.Like() is { } like)
            bookings = bookings.Where(b => EF.Functions.Like(b.Client.FirstName + " " + b.Client.LastName, like) ||
                                           EF.Functions.Like(b.Client.Email!, like) || EF.Functions.Like(b.Schedule.Room.Name, like));

        var sorted = query.IsNewestFirst()
            ? bookings.NewestFirst()
            : bookings.OrderByDescending(b => b.Schedule.Date).ThenByDescending(b => b.Schedule.StartTime);
        return sorted.Select(ToListItem).ToPagedResultAsync(query);
    }

    public Task<PagedResult<BookingListItemDto>> GetMineAsync(MyBookingsQuery query)
    {
        var upcoming = BookingRules.IsUpcoming(_clock.Now);
        var bookings = _db.Bookings.AsNoTracking().Where(b => b.ClientId == _currentUser.Id);
        if (query.Search.Like() is { } like) bookings = bookings.Where(b => EF.Functions.Like(b.Schedule.Room.Name, like));
        var ordered = query.Upcoming
            ? bookings.Where(upcoming).OrderBy(b => b.Schedule.Date).ThenBy(b => b.Schedule.StartTime)
            : bookings.Where(upcoming.Not()).OrderByDescending(b => b.Schedule.Date).ThenByDescending(b => b.Schedule.StartTime);

        return ordered.Select(ToListItem).ToPagedResultAsync(query);
    }

    public async Task<BookingDto> GetByIdAsync(int id)
    {
        var booking = await _db.Bookings.AsNoTracking().AsSplitQuery()
            .Include(b => b.Schedule).ThenInclude(s => s.Room).ThenInclude(r => r.Theme)
            .Include(b => b.Client)
            .Include(b => b.BookingStatus)
            .Include(b => b.Promotion)
            .Include(b => b.RewardRedemption).ThenInclude(r => r!.LoyaltyReward)
            .Include(b => b.BookingMembers)
            .Include(b => b.RoomResult).ThenInclude(r => r!.RecordedBy)
            .Include(b => b.StatusHistory).ThenInclude(h => h.FromStatus)
            .Include(b => b.StatusHistory).ThenInclude(h => h.ToStatus)
            .Include(b => b.StatusHistory).ThenInclude(h => h.ChangedBy)
            .Include(b => b.LoyaltyTransactions)
            .FirstOrDefaultAsync(b => b.Id == id)
            ?? throw new NotFoundException("Booking not found.");

        _access.EnsureCanAccessBooking(booking.ClientId, booking.Schedule.Room.ManagerId);
        var settings = await _settings.GetAsync();
        var hasReview = _currentUser.IsClient &&
                        await _db.Reviews.AnyAsync(r => r.ClientId == booking.ClientId && r.RoomId == booking.Schedule.RoomId);
        return BookingMapper.ToDto(booking, _currentUser, settings.CancellationDeadlineHours, hasReview, _clock.Now);
    }

    public async Task<BookingQuoteDto> QuoteAsync(CreateBookingRequest request)
    {
        var draft = await PrepareAsync(request);
        return new BookingQuoteDto
        {
            Subtotal = draft.Price.Subtotal,
            PromotionDiscount = draft.Price.PromotionDiscount,
            VoucherDiscount = draft.Price.VoucherDiscount,
            DiscountApplied = draft.Price.Discount,
            TotalPrice = draft.Price.Total,
            PromotionName = draft.Promotion?.Name,
            RewardName = draft.Redemption?.LoyaltyReward.Name
        };
    }

    public async Task<BookingDto> CreateAsync(CreateBookingRequest request)
    {
        var draft = await PrepareAsync(request);
        var booking = new Booking
        {
            ScheduleId = draft.Schedule.Id,
            ClientId = draft.ClientId,
            PlayerCount = request.PlayerCount,
            Subtotal = draft.Price.Subtotal,
            DiscountApplied = draft.Price.Discount,
            TotalPrice = draft.Price.Total,
            PromotionId = draft.Promotion?.Id,
            Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim(),
            BookingMembers = draft.ParticipantNames.Select(n => new BookingMember { ParticipantName = n }).ToList()
        };
        BookingStateMachine.Start(booking, _currentUser.Id);

        await using var transaction = await _db.Database.BeginTransactionAsync();
        _db.Bookings.Add(booking);
        await _db.SaveChangesAsync();
        if (draft.Redemption != null)
            await ClaimVoucherAsync(draft.Redemption.Id, booking.Id, VoucherField(request));
        await transaction.CommitAsync();

        _logger.LogInformation("Booking {BookingId} created for client {ClientId} on slot {ScheduleId} by {UserId}",
            booking.Id, booking.ClientId, booking.ScheduleId, _currentUser.Id);
        _events.Publish(EventQueues.BookingCreated, new BookingCreatedEvent(booking.Id, booking.ClientId));
        return await GetByIdAsync(booking.Id);
    }

    private async Task<BookingDraft> PrepareAsync(CreateBookingRequest request)
    {
        var clientId = await ResolveClientAsync(request.ClientId);
        var schedule = await LoadBookableScheduleAsync(request.ScheduleId);
        var room = schedule.Room;
        var errors = new Dictionary<string, string[]>();

        if (request.PlayerCount < room.MinPlayers || request.PlayerCount > room.MaxPlayers)
            errors["playerCount"] = [$"This room allows between {room.MinPlayers} and {room.MaxPlayers} players."];

        var names = request.ParticipantNames.Select(n => n?.Trim() ?? string.Empty).ToList();
        if (names.Any(n => n.Length is 0 or > 200))
            errors["participantNames"] = ["Each participant name must have between 1 and 200 characters."];
        else if (names.Count > request.PlayerCount)
            errors["participantNames"] = [$"You can enter at most {request.PlayerCount} participant names."];

        var promotion = await FindPromotionAsync(request.PromotionId, room.Id, errors);
        var redemption = await FindRedemptionAsync(request, clientId, errors);

        if (errors.Count > 0)
            throw new BusinessException(errors.First().Value[0], errors);

        var price = BookingPricing.Calculate(room, request.PlayerCount, promotion, redemption);
        return new BookingDraft(clientId, schedule, promotion, redemption, names, price);
    }

    private async Task<int> ResolveClientAsync(int? requestedClientId)
    {
        if (_currentUser.IsClient) return _currentUser.Id;

        if (requestedClientId == null)
            throw new BusinessException("Select a client for the booking.", "clientId");
        var exists = await _db.Users.Where(u => u.Id == requestedClientId && u.IsActive).InRoles(_db, Roles.Client).AnyAsync();
        if (!exists)
            throw new BusinessException("Select an active client from the list.", "clientId");
        return requestedClientId.Value;
    }

    private async Task<Schedule> LoadBookableScheduleAsync(int scheduleId)
    {
        var schedule = await _db.Schedules.Include(s => s.Room).Include(s => s.Bookings)
            .FirstOrDefaultAsync(s => s.Id == scheduleId)
            ?? throw new BusinessException("Select an available time slot.", "scheduleId");

        if (!_currentUser.IsClient) _access.EnsureCanManage(schedule.Room.ManagerId);

        var problem = !schedule.Room.IsActive ? "This room is not available for booking."
            : schedule.IsBlocked ? "This time slot is blocked."
            : schedule.StartsAt <= _clock.Now ? "This time slot has already started."
            : schedule.Bookings.Any(b => BookingRules.IsActiveStatus(b.BookingStatusId)) ? "This time slot is already booked."
            : null;
        if (problem != null)
            throw new BusinessException(problem, "scheduleId");
        return schedule;
    }

    private async Task<Promotion?> FindPromotionAsync(int? promotionId, int roomId, Dictionary<string, string[]> errors)
    {
        if (promotionId == null) return null;

        var promotion = await _db.Promotions.Include(p => p.PromotionType).Include(p => p.Rooms)
            .FirstOrDefaultAsync(p => p.Id == promotionId && !p.IsDeleted);
        var today = _clock.Today;
        var problem = promotion == null ? "Select a valid promotion."
            : !promotion.IsActive ? "This promotion is not active."
            : promotion.StartDate.Date > today || promotion.EndDate.Date < today ? "This promotion is not valid today."
            : promotion.Rooms.Count > 0 && promotion.Rooms.All(r => r.Id != roomId) ? "This promotion is not valid for this room."
            : null;

        if (problem == null) return promotion;
        errors["promotionId"] = [problem];
        return null;
    }

    private async Task<RewardRedemption?> FindRedemptionAsync(CreateBookingRequest request, int clientId, Dictionary<string, string[]> errors)
    {
        if (request.RedemptionId == null && string.IsNullOrWhiteSpace(request.VoucherCode)) return null;

        var code = request.VoucherCode?.Trim().ToUpperInvariant();
        var redemption = await _db.RewardRedemptions.AsNoTracking().Include(r => r.LoyaltyReward)
            .FirstOrDefaultAsync(r => request.RedemptionId != null ? r.Id == request.RedemptionId : r.Code == code);

        var problem = redemption == null || redemption.ClientId != clientId ? "This voucher code is not valid for this client."
            : redemption.IsUsed ? UsedVoucherMessage
            : null;

        if (problem == null) return redemption;
        errors[VoucherField(request)] = [problem];
        return null;
    }

    private async Task ClaimVoucherAsync(int redemptionId, int bookingId, string field)
    {
        var now = DateTime.UtcNow;
        var claimed = await _db.RewardRedemptions
            .Where(r => r.Id == redemptionId && !r.IsUsed)
            .ExecuteUpdateAsync(s => s
                .SetProperty(r => r.IsUsed, true)
                .SetProperty(r => r.UsedAt, now)
                .SetProperty(r => r.BookingId, bookingId)
                .SetProperty(r => r.UpdatedAt, now));
        if (claimed == 0)
            throw new ConflictException(UsedVoucherMessage, field);
    }

    private static string VoucherField(CreateBookingRequest request) => request.RedemptionId != null ? "redemptionId" : "voucherCode";

    private static readonly Expression<Func<Booking, BookingListItemDto>> ToListItem = b => new BookingListItemDto
    {
        Id = b.Id,
        RoomId = b.Schedule.RoomId,
        RoomName = b.Schedule.Room.Name,
        RoomImageUrl = b.Schedule.Room.ImageUrl,
        ThemeName = b.Schedule.Room.Theme.Name,
        ScheduleId = b.ScheduleId,
        Date = b.Schedule.Date,
        StartTime = BookingMapper.FormatTime(b.Schedule.StartTime),
        EndTime = BookingMapper.FormatTime(b.Schedule.EndTime),
        ClientId = b.ClientId,
        ClientName = b.Client.FirstName + " " + b.Client.LastName,
        ClientPictureUrl = b.Client.ProfilePictureUrl,
        StatusId = b.BookingStatusId,
        Status = b.BookingStatus.Name,
        PlayerCount = b.PlayerCount,
        TotalPrice = b.TotalPrice,
        HasResult = b.RoomResult != null,
        CreatedAt = b.CreatedAt
    };

    private record BookingDraft(int ClientId, Schedule Schedule, Promotion? Promotion, RewardRedemption? Redemption,
        List<string> ParticipantNames, BookingPrice Price);
}
