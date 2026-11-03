using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.RoomScenarios;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/room-scenarios")]
[Authorize]
public class RoomScenariosController : ControllerBase
{
    private readonly RoomScenarioService _scenarios;

    public RoomScenariosController(RoomScenarioService scenarios) => _scenarios = scenarios;

    [HttpGet]
    public Task<PagedResult<RoomScenarioDto>> GetAll([FromQuery] RoomScenarioQuery query) => _scenarios.GetAllAsync(query);

    [HttpGet("{id:int}")]
    public Task<RoomScenarioDto> Get(int id) => _scenarios.GetByIdAsync(id);

    [HttpPost]
    [Authorize(Roles = Roles.Staff)]
    public async Task<ActionResult<RoomScenarioDto>> Create(SaveRoomScenarioRequest request)
    {
        var scenario = await _scenarios.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = scenario.Id }, scenario);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<RoomScenarioDto> Update(int id, SaveRoomScenarioRequest request) => _scenarios.UpdateAsync(id, request);

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Delete(int id)
    {
        await _scenarios.DeleteAsync(id);
        return NoContent();
    }
}
