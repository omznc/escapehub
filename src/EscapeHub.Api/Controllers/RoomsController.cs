using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reviews;
using EscapeHub.Application.DTOs.Rooms;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/rooms")]
[Authorize]
public class RoomsController : ControllerBase
{
    private readonly RoomService _rooms;
    private readonly ReviewService _reviews;

    public RoomsController(RoomService rooms, ReviewService reviews)
    {
        _rooms = rooms;
        _reviews = reviews;
    }

    [HttpGet]
    public Task<PagedResult<RoomListItemDto>> GetAll([FromQuery] RoomQuery query) => _rooms.GetAllAsync(query);

    [HttpGet("{id:int}")]
    public Task<RoomDto> Get(int id) => _rooms.GetByIdAsync(id);

    [HttpGet("{id:int}/reviews")]
    public Task<PagedResult<ReviewDto>> GetReviews(int id, [FromQuery] ReviewQuery query) => _reviews.GetForRoomAsync(id, query);

    [HttpGet("{id:int}/stats")]
    [Authorize(Roles = Roles.Staff)]
    public Task<RoomStatsDto> GetStats(int id, [FromQuery, DateLimit] DateTime? from, [FromQuery, DateLimit] DateTime? to) => _rooms.GetStatsAsync(id, from, to);

    [HttpPost]
    [Authorize(Roles = Roles.Staff)]
    public async Task<ActionResult<RoomDto>> Create(SaveRoomRequest request)
    {
        var room = await _rooms.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = room.Id }, room);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<RoomDto> Update(int id, SaveRoomRequest request) => _rooms.UpdateAsync(id, request);

    [HttpPost("{id:int}/archive")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Archive(int id)
    {
        await _rooms.SetActiveAsync(id, false);
        return NoContent();
    }

    [HttpPost("{id:int}/restore")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Restore(int id)
    {
        await _rooms.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Delete(int id)
    {
        await _rooms.DeleteAsync(id);
        return NoContent();
    }
}
