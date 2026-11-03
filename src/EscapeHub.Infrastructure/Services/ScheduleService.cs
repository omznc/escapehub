using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Schedules;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class ScheduleService
{
    private const int MaxRangeDays = 92;

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;
    private readonly ILogger<ScheduleService> _logger;

    public ScheduleService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BusinessClock clock, ILogger<ScheduleService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _clock = clock;
        _logger = logger;
    }

    public async Task<PagedResult<ScheduleDto>> GetAllAsync(ScheduleQuery query)
    {
        var now = _clock.Now;
        var schedules = _db.Schedules.AsNoTracking();
        if (_access.ManagerScope is { } managerId) schedules = schedules.Where(s => s.Room.ManagerId == managerId);
        if (query.RoomId.HasValue) schedules = schedules.Where(s => s.RoomId == query.RoomId);
        if (query.From.HasValue) schedules = schedules.Where(s => s.Date >= query.From.Value.Date);
        if (query.To.HasValue) schedules = schedules.Where(s => s.Date <= query.To.Value.Date);
        if (query.Search.Like() is { } like)
            schedules = schedules.Where(s => EF.Functions.Like(s.Room.Name, like) ||
                s.Bookings.AsQueryable().Where(BookingRules.IsActive).Any(b => EF.Functions.Like(b.Client.FirstName + " " + b.Client.LastName, like)));
        if (query.Status != null) schedules = schedules.Where(HasStatus(query.Status, now));

        return await schedules.OrderBy(s => s.Date).ThenBy(s => s.StartTime).ThenBy(s => s.Room.Name)
            .Select(ToRow(now))
            .ToPagedResultAsync(query, ToDto);
    }

    public async Task<ScheduleDto> GetByIdAsync(int id)
    {
        var row = await _db.Schedules.AsNoTracking().Where(s => s.Id == id).Select(ToRow(_clock.Now)).FirstOrDefaultAsync()
            ?? throw new NotFoundException("Time slot not found.");
        await _access.EnsureCanManageRoomAsync(row.RoomId);
        return ToDto(row);
    }

    public async Task<PagedResult<SlotDto>> GetSlotsAsync(SlotQuery query)
    {
        var from = query.From!.Value.Date;
        var to = (query.To ?? from.AddDays(6)).Date;
        if (to < from) throw new BusinessException("End date must be on or after the start date.", "to");
        if ((to - from).TotalDays > MaxRangeDays) throw new BusinessException($"The date range can be at most {MaxRangeDays} days.", "to");
        if (!await _db.Rooms.AnyAsync(r => r.Id == query.RoomId && (r.IsActive || !_currentUser.IsClient)))
            throw new NotFoundException("Room not found.");

        var now = _clock.Now;
        var paging = new PaginationQuery { Page = query.Page, PageSize = query.PageSize };
        return await _db.Schedules.AsNoTracking()
            .Where(s => s.RoomId == query.RoomId && s.Date >= from && s.Date <= to)
            .OrderBy(s => s.Date).ThenBy(s => s.StartTime)
            .Select(ToRow(now))
            .ToPagedResultAsync(paging, ToSlot);
    }

    public async Task<ScheduleDto> CreateAsync(CreateScheduleRequest request)
    {
        await _access.EnsureCanAddSlotsAsync(request.RoomId, "roomId");
        var (date, start, end) = ParseSlot(request.Date!.Value, request.StartTime, request.EndTime);
        await EnsureNoOverlapAsync(request.RoomId, date, start, end, null);

        var schedule = new Schedule { RoomId = request.RoomId, Date = date, StartTime = start, EndTime = end, IsBlocked = request.IsBlocked };
        _db.Schedules.Add(schedule);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Time slot {ScheduleId} created for room {RoomId} by {UserId}", schedule.Id, schedule.RoomId, _currentUser.Id);
        return await GetByIdAsync(schedule.Id);
    }

    public async Task<ScheduleDto> UpdateAsync(int id, UpdateScheduleRequest request)
    {
        var schedule = await LoadManagedAsync(id);
        if (schedule.Bookings.Any(b => BookingRules.IsActiveStatus(b.BookingStatusId)))
            throw new ConflictException("This time slot has an active booking. Cancel the booking before you change the slot.");

        var (date, start, end) = ParseSlot(request.Date!.Value, request.StartTime, request.EndTime);
        await EnsureNoOverlapAsync(schedule.RoomId, date, start, end, id);
        schedule.Date = date;
        schedule.StartTime = start;
        schedule.EndTime = end;
        schedule.IsBlocked = request.IsBlocked;
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task<GenerateSchedulesResponse> GenerateAsync(GenerateSchedulesRequest request)
    {
        await _access.EnsureCanAddSlotsAsync(request.RoomId, "roomId");
        var startDate = request.StartDate!.Value.Date;
        var endDate = request.EndDate!.Value.Date;
        if (endDate < startDate) throw new BusinessException("End date must be on or after the start date.", "endDate");
        if ((endDate - startDate).TotalDays > MaxRangeDays) throw new BusinessException($"The date range can be at most {MaxRangeDays} days.", "endDate");

        var dayStart = TimeSpan.Parse(request.StartTime);
        var dayEnd = TimeSpan.Parse(request.EndTime);
        if (dayEnd <= dayStart) throw new BusinessException("Daily end time must be after the daily start time.", "endTime");

        var existing = await _db.Schedules.AsNoTracking()
            .Where(s => s.RoomId == request.RoomId && s.Date >= startDate && s.Date <= endDate)
            .Select(s => new { s.Date, s.StartTime, s.EndTime })
            .ToListAsync();

        var now = _clock.Now;
        var created = 0;
        var skipped = 0;
        foreach (var (date, start, end) in Slots(startDate, endDate, dayStart, dayEnd, request))
        {
            var overlaps = existing.Any(e => e.Date == date && start < e.EndTime && end > e.StartTime);
            if (overlaps || date + start <= now)
            {
                skipped++;
                continue;
            }
            _db.Schedules.Add(new Schedule { RoomId = request.RoomId, Date = date, StartTime = start, EndTime = end });
            created++;
        }
        await _db.SaveChangesAsync();

        _logger.LogInformation("Generated {Created} time slots for room {RoomId} by {UserId}", created, request.RoomId, _currentUser.Id);
        return new GenerateSchedulesResponse(created, skipped, $"Created {created} time slots. Skipped {skipped} slots that overlap or are in the past.");
    }

    public async Task DeleteAsync(int id)
    {
        var schedule = await LoadManagedAsync(id);
        if (schedule.Bookings.Count > 0)
            throw new ConflictException($"This time slot has {schedule.Bookings.Count.Counted("booking", "bookings")} in its history and cannot be deleted. Block it instead.");

        _db.Schedules.Remove(schedule);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Time slot {ScheduleId} deleted by {UserId}", id, _currentUser.Id);
    }

    private static IEnumerable<(DateTime Date, TimeSpan Start, TimeSpan End)> Slots(DateTime startDate, DateTime endDate,
        TimeSpan dayStart, TimeSpan dayEnd, GenerateSchedulesRequest request)
    {
        var duration = TimeSpan.FromMinutes(request.SlotDurationMinutes);
        var step = duration + TimeSpan.FromMinutes(request.BreakMinutes);
        for (var date = startDate; date <= endDate; date = date.AddDays(1))
        {
            if (!request.DaysOfWeek.Contains(date.DayOfWeek)) continue;
            for (var start = dayStart; start + duration <= dayEnd; start += step)
                yield return (date, start, start + duration);
        }
    }

    private async Task<Schedule> LoadManagedAsync(int id)
    {
        var schedule = await _db.Schedules.Include(s => s.Room).Include(s => s.Bookings).FirstOrDefaultAsync(s => s.Id == id)
            ?? throw new NotFoundException("Time slot not found.");
        _access.EnsureCanManage(schedule.Room.ManagerId);
        return schedule;
    }

    private (DateTime Date, TimeSpan Start, TimeSpan End) ParseSlot(DateTime date, string startTime, string endTime)
    {
        var start = TimeSpan.Parse(startTime);
        var end = TimeSpan.Parse(endTime);
        if (end <= start) throw new BusinessException("End time must be after the start time.", "endTime");
        if (date.Date + start <= _clock.Now) throw new BusinessException("You cannot create a time slot in the past.", "date");
        return (date.Date, start, end);
    }

    private async Task EnsureNoOverlapAsync(int roomId, DateTime date, TimeSpan start, TimeSpan end, int? exceptId)
    {
        var overlap = await _db.Schedules.AnyAsync(s => s.RoomId == roomId && s.Date == date && s.Id != exceptId &&
                                                        start < s.EndTime && end > s.StartTime);
        if (overlap)
            throw new BusinessException("This time overlaps another time slot of the same room.", "startTime");
    }

    private static Expression<Func<Schedule, bool>> HasStatus(string status, DateTime now)
    {
        var today = now.Date;
        var time = now.TimeOfDay;
        var active = BookingRules.IsActive;
        return status switch
        {
            SlotStatus.Booked => s => s.Bookings.AsQueryable().Any(active),
            SlotStatus.Past => s => !s.Bookings.AsQueryable().Any(active) && (s.Date < today || (s.Date == today && s.StartTime <= time)),
            SlotStatus.Blocked => s => !s.Bookings.AsQueryable().Any(active) && s.IsBlocked && (s.Date > today || (s.Date == today && s.StartTime > time)),
            _ => BookingRules.IsOpen(now)
        };
    }

    private static Expression<Func<Schedule, ScheduleRow>> ToRow(DateTime now)
    {
        var today = now.Date;
        var time = now.TimeOfDay;
        var active = BookingRules.IsActive;
        return s => new ScheduleRow
        {
            Id = s.Id,
            RoomId = s.RoomId,
            RoomName = s.Room.Name,
            Date = s.Date,
            StartTime = s.StartTime,
            EndTime = s.EndTime,
            IsBlocked = s.IsBlocked,
            IsPast = s.Date < today || (s.Date == today && s.StartTime <= time),
            Booking = s.Bookings.AsQueryable().Where(active).Select(b => new ActiveBooking
            {
                Id = b.Id,
                Status = b.BookingStatus.Name,
                ClientName = b.Client.FirstName + " " + b.Client.LastName
            }).FirstOrDefault(),
            BookingCount = s.Bookings.Count
        };
    }

    private ScheduleDto ToDto(ScheduleRow row)
    {
        var showBooking = !_currentUser.IsClient && row.Booking != null;
        return new ScheduleDto
        {
            Id = row.Id,
            RoomId = row.RoomId,
            RoomName = row.RoomName,
            Date = row.Date,
            StartTime = BookingMapper.FormatTime(row.StartTime),
            EndTime = BookingMapper.FormatTime(row.EndTime),
            IsBlocked = row.IsBlocked,
            Status = row.Status,
            BookingId = showBooking ? row.Booking!.Id : null,
            BookingStatus = showBooking ? row.Booking!.Status : null,
            ClientName = showBooking ? row.Booking!.ClientName : null,
            CanDelete = row.BookingCount == 0,
            DeleteBlockedReason = row.BookingCount == 0 ? null : "This time slot has bookings and cannot be deleted. Block it instead."
        };
    }

    private static SlotDto ToSlot(ScheduleRow row) => new()
    {
        Id = row.Id,
        RoomId = row.RoomId,
        Date = row.Date,
        StartTime = BookingMapper.FormatTime(row.StartTime),
        EndTime = BookingMapper.FormatTime(row.EndTime),
        Status = row.Status
    };

    private class ScheduleRow
    {
        public int Id { get; init; }
        public int RoomId { get; init; }
        public string RoomName { get; init; } = string.Empty;
        public DateTime Date { get; init; }
        public TimeSpan StartTime { get; init; }
        public TimeSpan EndTime { get; init; }
        public bool IsBlocked { get; init; }
        public bool IsPast { get; init; }
        public ActiveBooking? Booking { get; init; }
        public int BookingCount { get; init; }

        public string Status => Booking != null ? SlotStatus.Booked
            : IsPast ? SlotStatus.Past
            : IsBlocked ? SlotStatus.Blocked
            : SlotStatus.Available;
    }

    private class ActiveBooking
    {
        public int Id { get; init; }
        public string Status { get; init; } = string.Empty;
        public string ClientName { get; init; } = string.Empty;
    }
}
