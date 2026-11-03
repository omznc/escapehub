using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Promotions;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/promotions")]
[Authorize]
public class PromotionsController : ControllerBase
{
    private readonly PromotionService _promotions;

    public PromotionsController(PromotionService promotions) => _promotions = promotions;

    [HttpGet]
    [Authorize(Roles = Roles.Staff)]
    public Task<PagedResult<PromotionDto>> GetAll([FromQuery] PromotionQuery query) => _promotions.GetAllAsync(query);

    [HttpGet("active")]
    public Task<PagedResult<PromotionDto>> GetActive([FromQuery] ActivePromotionQuery query) => _promotions.GetActiveAsync(query);

    [HttpGet("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<PromotionDto> Get(int id) => _promotions.GetByIdAsync(id);

    [HttpPost]
    [Authorize(Roles = Roles.Staff)]
    public async Task<ActionResult<PromotionDto>> Create(SavePromotionRequest request)
    {
        var promotion = await _promotions.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = promotion.Id }, promotion);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public Task<PromotionDto> Update(int id, SavePromotionRequest request) => _promotions.UpdateAsync(id, request);

    [HttpPost("{id:int}/activate")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Activate(int id)
    {
        await _promotions.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpPost("{id:int}/deactivate")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Deactivate(int id)
    {
        await _promotions.SetActiveAsync(id, false);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Delete(int id)
    {
        await _promotions.DeleteAsync(id);
        return NoContent();
    }
}
