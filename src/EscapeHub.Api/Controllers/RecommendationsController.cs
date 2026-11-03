using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Recommendations;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/recommendations")]
[Authorize(Roles = Roles.Client)]
public class RecommendationsController : ControllerBase
{
    private readonly RecommendationService _recommendations;

    public RecommendationsController(RecommendationService recommendations) => _recommendations = recommendations;

    [HttpGet("me")]
    public Task<PagedResult<RecommendationDto>> GetMine([FromQuery] RecommendationQuery query) =>
        _recommendations.GetForCurrentUserAsync(query);
}
