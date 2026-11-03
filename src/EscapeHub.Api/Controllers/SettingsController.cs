using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Settings;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/settings")]
[Authorize]
public class SettingsController : ControllerBase
{
    private readonly SettingsService _settings;

    public SettingsController(SettingsService settings) => _settings = settings;

    [HttpGet]
    public Task<SettingsDto> Get() => _settings.GetAsync();

    [HttpPut]
    [Authorize(Roles = Roles.Administrator)]
    public Task<SettingsDto> Update(UpdateSettingsRequest request) => _settings.UpdateAsync(request);
}
