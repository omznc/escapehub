using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Dashboard;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/dashboard")]
[Authorize(Roles = Roles.Staff)]
public class DashboardController : ControllerBase
{
    private readonly DashboardService _dashboard;

    public DashboardController(DashboardService dashboard) => _dashboard = dashboard;

    [HttpGet("stats")]
    public Task<DashboardStatsDto> GetStats() => _dashboard.GetAsync();
}
