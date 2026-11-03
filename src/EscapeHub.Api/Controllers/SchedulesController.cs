using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Schedules;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/schedules")]
[Authorize]
public class SchedulesController : ControllerBase
{
    private readonly ScheduleService _schedules;

    public SchedulesController(ScheduleService schedules) => _schedules = schedules;

    [HttpGet]
    [Authorize(Roles = Roles.Staff)]
    public Task<PagedResult<ScheduleDto>> GetAll([FromQuery] ScheduleQuery query) => _schedules.GetAllAsync(query);

    [HttpGet("slots")]
    public Task<PagedResult<SlotDto>> GetSlots([FromQuery] SlotQuery query) => _schedules.GetSlotsAsync(query);

    [HttpGet("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<ScheduleDto> Get(int id) => _schedules.GetByIdAsync(id);

    [HttpPost]
    [Authorize(Roles = Roles.Staff)]
    public async Task<ActionResult<ScheduleDto>> Create(CreateScheduleRequest request)
    {
        var schedule = await _schedules.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = schedule.Id }, schedule);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<ScheduleDto> Update(int id, UpdateScheduleRequest request) => _schedules.UpdateAsync(id, request);

    [HttpPost("generate")]
    [Authorize(Roles = Roles.Staff)]
    public Task<GenerateSchedulesResponse> Generate(GenerateSchedulesRequest request) => _schedules.GenerateAsync(request);

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Delete(int id)
    {
        await _schedules.DeleteAsync(id);
        return NoContent();
    }
}
