using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Api.Infrastructure;

public static class RateLimitingSetup
{
    public const string AuthPolicy = "auth";

    public static IServiceCollection AddAuthRateLimiting(this IServiceCollection services, AuthRateLimitOptions limit)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddPolicy(AuthPolicy, context => RateLimitPartition.GetFixedWindowLimiter(
                context.Connection.RemoteIpAddress?.ToString() ?? string.Empty,
                _ => new FixedWindowRateLimiterOptions { PermitLimit = limit.PermitLimit, Window = limit.Window }));
            options.OnRejected = (context, cancellationToken) => new ValueTask(context.HttpContext.Response.WriteAsJsonAsync(
                ErrorResponse.From($"Too many attempts. Wait {limit.Window.TotalSeconds:0} seconds and try again."), cancellationToken));
        });
        return services;
    }
}
