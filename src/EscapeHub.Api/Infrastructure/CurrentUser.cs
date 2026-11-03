using System.Security.Claims;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;

namespace EscapeHub.Api.Infrastructure;

public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUser(IHttpContextAccessor accessor) => _accessor = accessor;

    private ClaimsPrincipal Principal => _accessor.HttpContext?.User ?? new ClaimsPrincipal();

    public int Id => int.Parse(Principal.FindFirstValue(ClaimTypes.NameIdentifier)
                               ?? throw new InvalidOperationException("The request has no authenticated user."));

    private string Role => Principal.FindFirstValue(ClaimTypes.Role) ?? string.Empty;

    public bool IsAdmin => Role == Roles.Administrator;
    public bool IsManager => Role == Roles.RoomManager;
    public bool IsClient => Role == Roles.Client;
}
