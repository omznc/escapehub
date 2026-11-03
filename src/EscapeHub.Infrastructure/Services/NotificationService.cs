using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Notifications;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class NotificationService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public NotificationService(AppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public Task<PagedResult<NotificationDto>> GetMineAsync(NotificationQuery query)
    {
        var notifications = Mine().AsNoTracking();
        if (query.UnreadOnly == true) notifications = notifications.Where(n => !n.IsRead);
        if (query.Search.Like() is { } like)
            notifications = notifications.Where(n => EF.Functions.Like(n.Title, like) || EF.Functions.Like(n.Message, like));

        return notifications.OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id).ToPagedResultAsync(query, ToDto);
    }

    public async Task<CountResponse> GetUnreadCountAsync() =>
        new(await Mine().CountAsync(n => !n.IsRead));

    public async Task MarkAsReadAsync(int id)
    {
        var notification = await Mine().FirstOrDefaultAsync(n => n.Id == id)
            ?? throw new NotFoundException("Notification not found.");
        notification.IsRead = true;
        await _db.SaveChangesAsync();
    }

    public async Task<CountResponse> MarkAllAsReadAsync()
    {
        var now = DateTime.UtcNow;
        var count = await Mine().Where(n => !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true).SetProperty(n => n.UpdatedAt, now));
        return new CountResponse(count);
    }

    private IQueryable<Notification> Mine() => _db.Notifications.Where(n => n.UserId == _currentUser.Id);

    private static NotificationDto ToDto(Notification n) => new()
    {
        Id = n.Id,
        Title = n.Title,
        Message = n.Message,
        Type = n.Type.ToString(),
        IsRead = n.IsRead,
        CreatedAt = n.CreatedAt
    };
}
