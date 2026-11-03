using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Api.Infrastructure;

public static class AuthenticationSetup
{
    public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, JwtOptions jwt)
    {
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwt.Issuer,
                    ValidAudience = jwt.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Secret)),
                    NameClaimType = ClaimTypes.Name,
                    RoleClaimType = ClaimTypes.Role,
                    ClockSkew = TimeSpan.FromMinutes(1)
                };
                options.Events = new JwtBearerEvents
                {
                    OnTokenValidated = ValidateSessionAsync,
                    OnChallenge = async context =>
                    {
                        context.HandleResponse();
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        await context.Response.WriteAsJsonAsync(ErrorResponse.From("Sign in to continue. Your session is missing or has expired."));
                    },
                    OnForbidden = context =>
                    {
                        context.Response.StatusCode = StatusCodes.Status403Forbidden;
                        return context.Response.WriteAsJsonAsync(ErrorResponse.From("You do not have permission to perform this action."));
                    }
                };
            });
        return services;
    }

    private static async Task ValidateSessionAsync(TokenValidatedContext context)
    {
        var principal = context.Principal!;
        var sessions = context.HttpContext.RequestServices.GetRequiredService<SessionValidator>();
        var valid = int.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) &&
                    await sessions.IsValidAsync(userId, principal.FindFirstValue(SessionValidator.StampClaim));
        if (!valid)
            context.Fail("The session is no longer valid.");
    }
}
