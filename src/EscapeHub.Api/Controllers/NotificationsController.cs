using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Notifications;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly NotificationService _notifications;

    public NotificationsController(NotificationService notifications) => _notifications = notifications;

    [HttpGet]
    public Task<PagedResult<NotificationDto>> GetMine([FromQuery] NotificationQuery query) => _notifications.GetMineAsync(query);

    [HttpGet("unread-count")]
    public Task<CountResponse> GetUnreadCount() => _notifications.GetUnreadCountAsync();

    [HttpPost("{id:int}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        await _notifications.MarkAsReadAsync(id);
        return NoContent();
    }

    [HttpPost("read-all")]
    public Task<CountResponse> MarkAllAsRead() => _notifications.MarkAllAsReadAsync();
}
