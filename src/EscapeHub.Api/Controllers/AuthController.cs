using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using EscapeHub.Api.Infrastructure;
using EscapeHub.Application.DTOs.Auth;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/auth")]
[Authorize]
public class AuthController : ControllerBase
{
    private readonly AuthService _auth;

    public AuthController(AuthService auth) => _auth = auth;

    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitingSetup.AuthPolicy)]
    public Task<AuthResponse> Login(LoginRequest request) => _auth.LoginAsync(request, staffOnly: false);

    [HttpPost("desktop-login")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitingSetup.AuthPolicy)]
    public Task<AuthResponse> DesktopLogin(LoginRequest request) => _auth.LoginAsync(request, staffOnly: true);

    [HttpPost("register")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitingSetup.AuthPolicy)]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request) =>
        StatusCode(StatusCodes.Status201Created, await _auth.RegisterAsync(request));

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitingSetup.AuthPolicy)]
    public async Task<MessageResponse> ForgotPassword(ForgotPasswordRequest request)
    {
        await _auth.RequestPasswordResetAsync(request);
        return new MessageResponse("If an account with this email exists, we sent a reset code to it.");
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitingSetup.AuthPolicy)]
    public async Task<MessageResponse> ResetPassword(ResetPasswordRequest request)
    {
        await _auth.ResetPasswordAsync(request);
        return new MessageResponse("Your password was changed. Sign in with the new password.");
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        await _auth.LogoutAsync();
        return NoContent();
    }

    [HttpGet("me")]
    public Task<UserDto> Me() => _auth.GetCurrentUserAsync();

    [HttpPut("profile")]
    public Task<UserDto> UpdateProfile(UpdateProfileRequest request) => _auth.UpdateProfileAsync(request);

    [HttpPost("change-password")]
    public async Task<MessageResponse> ChangePassword(ChangePasswordRequest request)
    {
        await _auth.ChangePasswordAsync(request);
        return new MessageResponse("Your password was changed. Sign in again with the new password.");
    }
}
