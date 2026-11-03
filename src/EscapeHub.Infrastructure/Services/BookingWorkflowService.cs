using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class BookingWorkflowService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly SettingsService _settings;
    private readonly IEventPublisher _events;
    private readonly BusinessClock _clock;
    private readonly ILogger<BookingWorkflowService> _logger;

    public BookingWorkflowService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, SettingsService settings,
        IEventPublisher events, BusinessClock clock, ILogger<BookingWorkflowService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _settings = settings;
        _events = events;
        _clock = clock;
        _logger = logger;
    }

    public async Task ConfirmAsync(int id)
    {
        var booking = await LoadAsync(id);
        EnsureAllowed(booking, BookingStatusEnum.Confirmed);
        await ChangeStatusAsync(booking, BookingStatusEnum.Confirmed, null);
    }

    public async Task RejectAsync(int id, RejectBookingRequest request)
    {
        var booking = await LoadAsync(id);
        ReleaseVoucher(booking);
        await ChangeStatusAsync(booking, BookingStatusEnum.Rejected, request.Reason);
    }

    public async Task CancelAsync(int id, ReasonRequest request)
    {
        var booking = await LoadAsync(id);
        var settings = await _settings.GetAsync();
        var (canCancel, reason) = BookingMapper.CancelState(booking, _currentUser, settings.CancellationDeadlineHours, _clock.Now);
        if (!canCancel)
            throw new ConflictException(reason!);

        ReleaseVoucher(booking);
        await ChangeStatusAsync(booking, BookingStatusEnum.Cancelled, request.Reason);
    }

    public async Task MarkNoShowAsync(int id)
    {
        var booking = await LoadAsync(id);
        EnsureAllowed(booking, BookingStatusEnum.NoShow);
        await ChangeStatusAsync(booking, BookingStatusEnum.NoShow, null);
    }

    public async Task CompleteAsync(int id, CompleteBookingRequest request)
    {
        var booking = await LoadAsync(id);
        EnsureAllowed(booking, BookingStatusEnum.Completed);
        BookingStateMachine.Move(booking, BookingStatusEnum.Completed, _currentUser.Id, null);
        if (request.Result != null)
            _db.RoomResults.Add(CreateResult(booking.Id, request.Result));

        await _db.SaveChangesAsync();
        _logger.LogInformation("Booking {BookingId} completed by {UserId}", id, _currentUser.Id);

        _events.Publish(EventQueues.BookingCompleted, new BookingCompletedEvent(booking.Id, booking.ClientId));
        if (request.Result != null)
            _events.Publish(EventQueues.ResultRecorded, new ResultRecordedEvent(booking.Id, booking.ClientId));
    }

    public async Task RecordResultAsync(int id, SaveRoomResultRequest request)
    {
        var booking = await LoadAsync(id);
        if (BookingStateMachine.StatusOf(booking) != BookingStatusEnum.Completed)
            throw new ConflictException("You can record a result only for a completed booking.");
        if (await _db.RoomResults.AnyAsync(r => r.BookingId == id))
            throw new ConflictException("A result is already recorded for this booking. Edit the existing result.");

        _db.RoomResults.Add(CreateResult(id, request));
        await _db.SaveChangesAsync();
        _logger.LogInformation("Result recorded for booking {BookingId} by {UserId}", id, _currentUser.Id);
        _events.Publish(EventQueues.ResultRecorded, new ResultRecordedEvent(booking.Id, booking.ClientId));
    }

    public async Task UpdateResultAsync(int id, SaveRoomResultRequest request)
    {
        await LoadAsync(id);
        var result = await _db.RoomResults.FirstOrDefaultAsync(r => r.BookingId == id)
            ?? throw new NotFoundException("No result is recorded for this booking.");

        result.Escaped = request.Escaped;
        result.CompletionTimeMinutes = request.CompletionTimeMinutes;
        result.HintsUsed = request.HintsUsed;
        result.ManagerNotes = request.ManagerNotes;
        result.Score = request.Score;
        result.RecordedById = _currentUser.Id;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Result of booking {BookingId} updated by {UserId}", id, _currentUser.Id);
    }

    private async Task ChangeStatusAsync(Booking booking, BookingStatusEnum to, string? reason)
    {
        var from = BookingStateMachine.Move(booking, to, _currentUser.Id, reason);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Booking {BookingId} moved from {From} to {To} by {UserId}", booking.Id, from, to, _currentUser.Id);
        _events.Publish(EventQueues.BookingStatusChanged,
            new BookingStatusChangedEvent(booking.Id, booking.ClientId, (int)from, (int)to, reason, _currentUser.Id));
    }

    private async Task<Booking> LoadAsync(int id)
    {
        var booking = await _db.Bookings
            .Include(b => b.Schedule).ThenInclude(s => s.Room)
            .Include(b => b.RewardRedemption)
            .FirstOrDefaultAsync(b => b.Id == id)
            ?? throw new NotFoundException("Booking not found.");
        _access.EnsureCanAccessBooking(booking.ClientId, booking.Schedule.Room.ManagerId);
        return booking;
    }

    private void EnsureAllowed(Booking booking, BookingStatusEnum target)
    {
        if (BookingMapper.BlockedReason(booking, target, _clock.Now) is { } reason)
            throw new ConflictException(reason);
    }

    private static void ReleaseVoucher(Booking booking)
    {
        if (booking.RewardRedemption == null) return;
        booking.RewardRedemption.IsUsed = false;
        booking.RewardRedemption.UsedAt = null;
        booking.RewardRedemption.BookingId = null;
    }

    private RoomResult CreateResult(int bookingId, SaveRoomResultRequest request) => new()
    {
        BookingId = bookingId,
        Escaped = request.Escaped,
        CompletionTimeMinutes = request.CompletionTimeMinutes,
        HintsUsed = request.HintsUsed,
        ManagerNotes = request.ManagerNotes,
        Score = request.Score,
        RecordedById = _currentUser.Id
    };
}
