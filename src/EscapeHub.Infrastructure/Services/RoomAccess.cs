using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services;

public class RoomAccess
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _user;

    public RoomAccess(AppDbContext db, ICurrentUser user)
    {
        _db = db;
        _user = user;
    }

    public int? ManagerScope => _user.IsManager ? _user.Id : null;

    public IQueryable<Room> ManagedRooms() =>
        ManagerScope is { } managerId ? _db.Rooms.Where(r => r.ManagerId == managerId) : _db.Rooms;

    public IQueryable<Promotion> VisiblePromotions()
    {
        var promotions = _db.Promotions.Where(p => !p.IsDeleted);
        return ManagerScope is { } managerId
            ? promotions.Where(p => !p.Rooms.Any() || p.Rooms.Any(r => r.ManagerId == managerId))
            : promotions;
    }

    public async Task<Room> GetManagedRoomAsync(int roomId)
    {
        var room = await _db.Rooms.FirstOrDefaultAsync(r => r.Id == roomId)
            ?? throw new NotFoundException("Room not found.");
        EnsureCanManage(room.ManagerId);
        return room;
    }

    public async Task EnsureCanManageRoomAsync(int roomId, string? field = null)
    {
        var room = await _db.Rooms.Where(r => r.Id == roomId).Select(r => new { r.ManagerId }).FirstOrDefaultAsync();
        if (room == null)
        {
            if (field != null) throw new BusinessException("Select a room from the list.", field);
            throw new NotFoundException("Room not found.");
        }
        EnsureCanManage(room.ManagerId);
    }

    public async Task EnsureCanAddSlotsAsync(int roomId, string field)
    {
        var room = await _db.Rooms.Where(r => r.Id == roomId).Select(r => new { r.ManagerId, r.IsActive }).FirstOrDefaultAsync()
            ?? throw new BusinessException("Select a room from the list.", field);
        EnsureCanManage(room.ManagerId);
        if (!room.IsActive)
            throw new BusinessException("This room is archived. Restore it before you add time slots.", field);
    }

    public void EnsureCanAccessBooking(int clientId, int? roomManagerId)
    {
        if (_user.IsClient && clientId != _user.Id)
            throw new ForbiddenException("You can access only your own bookings.");
        if (!_user.IsClient)
            EnsureCanManage(roomManagerId);
    }

    public void EnsureCanManage(int? roomManagerId)
    {
        if (ManagerScope is { } managerId && roomManagerId != managerId)
            throw new ForbiddenException("You can manage only the rooms that are assigned to you.");
    }
}
