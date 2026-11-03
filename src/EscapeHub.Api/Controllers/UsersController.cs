using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/users")]
[Authorize(Roles = Roles.Administrator)]
public class UsersController : ControllerBase
{
    private readonly UserService _users;

    public UsersController(UserService users) => _users = users;

    [HttpGet]
    public Task<PagedResult<UserDto>> GetAll([FromQuery] UserQuery query) => _users.GetStaffAsync(query);

    [HttpGet("{id:int}")]
    public Task<UserDto> Get(int id) => _users.GetByIdAsync(id);

    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(CreateUserRequest request)
    {
        var user = await _users.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = user.Id }, user);
    }

    [HttpPut("{id:int}")]
    public Task<UserDto> Update(int id, UpdateUserRequest request) => _users.UpdateAsync(id, request);

    [HttpPost("{id:int}/activate")]
    public async Task<IActionResult> Activate(int id)
    {
        await _users.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpPost("{id:int}/deactivate")]
    public async Task<IActionResult> Deactivate(int id)
    {
        await _users.SetActiveAsync(id, false);
        return NoContent();
    }

    [HttpPost("{id:int}/reset-password")]
    public async Task<MessageResponse> ResetPassword(int id, AdminResetPasswordRequest request)
    {
        await _users.ResetPasswordAsync(id, request);
        return new MessageResponse("The password was reset. The user must sign in again.");
    }
}
