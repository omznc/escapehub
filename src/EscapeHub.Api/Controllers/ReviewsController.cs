using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reviews;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/reviews")]
[Authorize]
public class ReviewsController : ControllerBase
{
    private readonly ReviewService _reviews;

    public ReviewsController(ReviewService reviews) => _reviews = reviews;

    [HttpGet]
    [Authorize(Roles = Roles.Staff)]
    public Task<PagedResult<ReviewDto>> GetAll([FromQuery] ReviewQuery query) => _reviews.GetAllAsync(query);

    [HttpGet("me")]
    [Authorize(Roles = Roles.Client)]
    public Task<PagedResult<ReviewDto>> GetMine([FromQuery] MyReviewsQuery query) => _reviews.GetMineAsync(query);

    [HttpPost]
    [Authorize(Roles = Roles.Client)]
    public async Task<ActionResult<ReviewDto>> Create(CreateReviewRequest request) =>
        StatusCode(StatusCodes.Status201Created, await _reviews.CreateAsync(request));

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Client)]
    public Task<ReviewDto> Update(int id, UpdateReviewRequest request) => _reviews.UpdateAsync(id, request);

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Client)]
    public async Task<IActionResult> Delete(int id)
    {
        await _reviews.DeleteAsync(id);
        return NoContent();
    }

    [HttpPost("{id:int}/hide")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Hide(int id)
    {
        await _reviews.SetHiddenAsync(id, true);
        return NoContent();
    }

    [HttpPost("{id:int}/unhide")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<IActionResult> Unhide(int id)
    {
        await _reviews.SetHiddenAsync(id, false);
        return NoContent();
    }
}
