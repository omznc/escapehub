using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Infrastructure.Services;

public class UserService
{
    private readonly AppDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ICurrentUser _currentUser;
    private readonly SessionValidator _sessions;
    private readonly ILogger<UserService> _logger;

    public UserService(AppDbContext db, UserManager<ApplicationUser> userManager, ICurrentUser currentUser,
        SessionValidator sessions, ILogger<UserService> logger)
    {
        _db = db;
        _userManager = userManager;
        _currentUser = currentUser;
        _sessions = sessions;
        _logger = logger;
    }

    public Task<PagedResult<UserDto>> GetStaffAsync(UserQuery query)
    {
        if (query.Role != null) EnsureStaffRole(query.Role);
        var roles = query.Role != null ? [query.Role] : Roles.StaffRoles;
        return SearchAsync(_db.Users.InRoles(_db, roles), query);
    }

    public Task<PagedResult<UserDto>> GetClientsAsync(UserQuery query) =>
        SearchAsync(_db.Users.InRoles(_db, Roles.Client), query);

    public async Task<UserDto> GetByIdAsync(int id, string? requiredRole = null)
    {
        var users = _db.Users.AsNoTracking().Where(u => u.Id == id);
        if (requiredRole != null) users = users.InRoles(_db, requiredRole);
        return await users.Select(UserProjection.ToDto(_db)).FirstOrDefaultAsync()
            ?? throw new NotFoundException("User not found.");
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request)
    {
        EnsureStaffRole(request.Role);
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
        IdentityErrors.ThrowIfFailed(await _userManager.AddToRoleAsync(user, request.Role));
        await transaction.CommitAsync();

        _logger.LogInformation("User {UserId} created with role {Role} by {AdminId}", user.Id, request.Role, _currentUser.Id);
        return await GetByIdAsync(user.Id);
    }

    public async Task<UserDto> UpdateAsync(int id, UpdateUserRequest request)
    {
        EnsureStaffRole(request.Role);
        await _db.EnsureCityExistsAsync(request.CityId);
        var user = await FindAsync(id);
        if (user.Id == _currentUser.Id && request.Role != Roles.Administrator)
            throw new BusinessException("You cannot remove the administrator role from your own account.", "role");

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = request.Email.Trim();
        user.PhoneNumber = request.Phone;
        user.CityId = request.CityId;

        await using var transaction = await _db.Database.BeginTransactionAsync();
        IdentityErrors.ThrowIfFailed(await _userManager.UpdateAsync(user));
        await ReplaceRoleAsync(user, request.Role);
        await transaction.CommitAsync();

        return await GetByIdAsync(id);
    }

    public async Task SetActiveAsync(int id, bool isActive)
    {
        if (id == _currentUser.Id && !isActive)
            throw new ConflictException("You cannot deactivate your own account.");

        var user = await FindAsync(id);
        user.IsActive = isActive;
        await using var transaction = await _db.Database.BeginTransactionAsync();
        IdentityErrors.ThrowIfFailed(await _userManager.UpdateAsync(user));
        if (!isActive)
            IdentityErrors.ThrowIfFailed(await _userManager.UpdateSecurityStampAsync(user));
        await transaction.CommitAsync();
        _sessions.Invalidate(id);
        _logger.LogInformation("User {UserId} active state set to {IsActive} by {AdminId}", id, isActive, _currentUser.Id);
    }

    public async Task ResetPasswordAsync(int id, AdminResetPasswordRequest request)
    {
        if (id == _currentUser.Id)
            throw new BusinessException("Use Change password in your account menu to change your own password.", "newPassword");
        var user = await FindAsync(id);
        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        IdentityErrors.ThrowIfFailed(await _userManager.ResetPasswordAsync(user, token, request.NewPassword), "newPassword");
        _sessions.Invalidate(id);
        _logger.LogInformation("Password of user {UserId} reset by {AdminId}", id, _currentUser.Id);
    }

    private async Task<PagedResult<UserDto>> SearchAsync(IQueryable<ApplicationUser> users, UserQuery query)
    {
        users = users.AsNoTracking();
        if (query.IsActive.HasValue) users = users.Where(u => u.IsActive == query.IsActive);
        if (query.Search.Like() is { } like)
            users = users.Where(u => EF.Functions.Like(u.UserName!, like) || EF.Functions.Like(u.Email!, like) ||
                                     EF.Functions.Like(u.FirstName + " " + u.LastName, like));

        var sorted = query.IsNewestFirst()
            ? users.OrderByDescending(u => u.CreatedAt).ThenByDescending(u => u.Id)
            : users.OrderBy(u => u.LastName).ThenBy(u => u.FirstName);
        return await sorted
            .Select(UserProjection.ToDto(_db))
            .ToPagedResultAsync(query);
    }

    private async Task ReplaceRoleAsync(ApplicationUser user, string role)
    {
        var current = await _userManager.GetRolesAsync(user);
        if (current.Count == 1 && current[0] == role) return;
        IdentityErrors.ThrowIfFailed(await _userManager.RemoveFromRolesAsync(user, current));
        IdentityErrors.ThrowIfFailed(await _userManager.AddToRoleAsync(user, role));
        await _userManager.UpdateSecurityStampAsync(user);
        _sessions.Invalidate(user.Id);
    }

    private async Task<ApplicationUser> FindAsync(int id) =>
        await _userManager.FindByIdAsync(id.ToString()) ?? throw new NotFoundException("User not found.");

    private static void EnsureStaffRole(string role)
    {
        if (!Roles.StaffRoles.Contains(role))
            throw new BusinessException("Role must be Administrator or RoomManager.", "role");
    }
}
