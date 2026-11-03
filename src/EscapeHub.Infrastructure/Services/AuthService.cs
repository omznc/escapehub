using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.DTOs.Auth;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Infrastructure.Services;

public class AuthService
{
    private const int MaxResetAttempts = 5;
    private const string InvalidCodeMessage = "The code is invalid or expired. Request a new code.";

    private readonly AppDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IPasswordHasher<ApplicationUser> _hasher;
    private readonly ICurrentUser _currentUser;
    private readonly IEventPublisher _events;
    private readonly SessionValidator _sessions;
    private readonly JwtOptions _jwt;
    private readonly PasswordResetOptions _resetOptions;
    private readonly ILogger<AuthService> _logger;

    public AuthService(AppDbContext db, UserManager<ApplicationUser> userManager, IPasswordHasher<ApplicationUser> hasher,
        ICurrentUser currentUser, IEventPublisher events, SessionValidator sessions, JwtOptions jwt,
        PasswordResetOptions resetOptions, ILogger<AuthService> logger)
    {
        _db = db;
        _userManager = userManager;
        _hasher = hasher;
        _currentUser = currentUser;
        _events = events;
        _sessions = sessions;
        _jwt = jwt;
        _resetOptions = resetOptions;
        _logger = logger;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, bool staffOnly)
    {
        var user = await _userManager.FindByNameAsync(request.Username);
        if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
            throw new AuthenticationFailedException("Invalid username or password.");
        if (!user.IsActive)
            throw new AuthenticationFailedException("This account is deactivated. Contact the administrator.");

        var role = await GetRoleAsync(user);
        if (staffOnly && role == Roles.Client)
            throw new ForbiddenException("Client accounts cannot sign in to the desktop application. Use the mobile application.");

        _logger.LogInformation("User {UserId} signed in as {Role}", user.Id, role);
        return CreateAuthResponse(user, role);
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        await _db.EnsureCityExistsAsync(request.CityId);

        var user = new ApplicationUser
        {
            UserName = request.Username.Trim(),
            Email = request.Email.Trim(),
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PhoneNumber = request.Phone,
            CityId = request.CityId
        };

        await using var transaction = await _db.Database.BeginTransactionAsync();
        IdentityErrors.ThrowIfFailed(await _userManager.CreateAsync(user, request.Password));
        IdentityErrors.ThrowIfFailed(await _userManager.AddToRoleAsync(user, Roles.Client));
        await transaction.CommitAsync();

        _logger.LogInformation("Client {UserId} registered", user.Id);
        return CreateAuthResponse(user, Roles.Client);
    }

    public async Task<UserDto> GetCurrentUserAsync()
    {
        return await _db.Users.AsNoTracking()
            .Where(u => u.Id == _currentUser.Id)
            .Select(UserProjection.ToDto(_db))
            .FirstOrDefaultAsync() ?? throw new NotFoundException("User not found.");
    }

    public async Task<UserDto> UpdateProfileAsync(UpdateProfileRequest request)
    {
        await _db.EnsureCityExistsAsync(request.CityId);
        var user = await _userManager.FindByIdAsync(_currentUser.Id.ToString())
            ?? throw new NotFoundException("User not found.");

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = request.Email.Trim();
        user.PhoneNumber = request.Phone;
        user.CityId = request.CityId;
        IdentityErrors.ThrowIfFailed(await _userManager.UpdateAsync(user));

        return await GetCurrentUserAsync();
    }

    public async Task ChangePasswordAsync(ChangePasswordRequest request)
    {
        var user = await _userManager.FindByIdAsync(_currentUser.Id.ToString())
            ?? throw new NotFoundException("User not found.");
        IdentityErrors.ThrowIfFailed(
            await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword), "newPassword");
        _sessions.Invalidate(user.Id);
    }

    public async Task LogoutAsync()
    {
        var user = await _userManager.FindByIdAsync(_currentUser.Id.ToString())
            ?? throw new NotFoundException("User not found.");
        await _userManager.UpdateSecurityStampAsync(user);
        _sessions.Invalidate(user.Id);
        _logger.LogInformation("User {UserId} signed out", user.Id);
    }

    public async Task RequestPasswordResetAsync(ForgotPasswordRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim());
        if (user == null || !user.IsActive)
        {
            _logger.LogInformation("Password reset requested for an unknown or inactive email");
            return;
        }

        var openCodes = await _db.PasswordResetCodes.Where(c => c.UserId == user.Id && c.UsedAt == null).ToListAsync();
        var now = DateTime.UtcNow;
        openCodes.ForEach(c => c.UsedAt = now);

        var code = SecureCodes.NumericCode(6);
        _db.PasswordResetCodes.Add(new PasswordResetCode
        {
            UserId = user.Id,
            CodeHash = _hasher.HashPassword(user, code),
            ExpiresAt = now.AddMinutes(_resetOptions.CodeLifetimeMinutes)
        });
        await _db.SaveChangesAsync();

        _events.Publish(EventQueues.PasswordResetRequested,
            new PasswordResetRequestedEvent(user.Id, user.Email!, code, _resetOptions.CodeLifetimeMinutes));
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim())
            ?? throw new BusinessException(InvalidCodeMessage, "code");

        var now = DateTime.UtcNow;
        var resetCode = await _db.PasswordResetCodes.AsNoTracking()
            .Where(c => c.UserId == user.Id && c.UsedAt == null && c.ExpiresAt > now)
            .OrderByDescending(c => c.CreatedAt)
            .FirstOrDefaultAsync()
            ?? throw new BusinessException(InvalidCodeMessage, "code");

        var claimed = await _db.PasswordResetCodes
            .Where(c => c.Id == resetCode.Id && c.FailedAttempts < MaxResetAttempts && c.UsedAt == null && c.ExpiresAt > now)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.FailedAttempts, c => c.FailedAttempts + 1).SetProperty(c => c.UpdatedAt, now));
        if (claimed == 0)
            throw new BusinessException(InvalidCodeMessage, "code");
        if (_hasher.VerifyHashedPassword(user, resetCode.CodeHash, request.Code) == PasswordVerificationResult.Failed)
            throw new BusinessException("The code is not correct.", "code");

        await using var transaction = await _db.Database.BeginTransactionAsync();
        var used = await _db.PasswordResetCodes
            .Where(c => c.Id == resetCode.Id && c.UsedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.UsedAt, now).SetProperty(c => c.UpdatedAt, now));
        if (used == 0)
            throw new BusinessException(InvalidCodeMessage, "code");
        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        IdentityErrors.ThrowIfFailed(await _userManager.ResetPasswordAsync(user, token, request.NewPassword), "newPassword");
        await transaction.CommitAsync();

        _sessions.Invalidate(user.Id);
        _logger.LogInformation("User {UserId} reset the password with an email code", user.Id);
    }

    private async Task<string> GetRoleAsync(ApplicationUser user) =>
        (await _userManager.GetRolesAsync(user)).FirstOrDefault() ?? Roles.Client;

    private AuthResponse CreateAuthResponse(ApplicationUser user, string role)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(_jwt.ExpiryMinutes);
        return new AuthResponse
        {
            Token = CreateToken(user, role, expiresAt),
            ExpiresAt = expiresAt,
            UserId = user.Id,
            Username = user.UserName!,
            Email = user.Email!,
            FirstName = user.FirstName,
            LastName = user.LastName,
            ProfilePictureUrl = user.ProfilePictureUrl,
            Role = role,
            IsStaff = role != Roles.Client
        };
    }

    private string CreateToken(ApplicationUser user, string role, DateTime expiresAt)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.UserName!),
            new(ClaimTypes.Role, role),
            new(SessionValidator.StampClaim, user.SecurityStamp!)
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Secret));
        var token = new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
