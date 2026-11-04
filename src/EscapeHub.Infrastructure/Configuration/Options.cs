using Microsoft.Extensions.Configuration;

namespace EscapeHub.Infrastructure.Configuration;

public class RabbitMqOptions
{
    public string Host { get; init; } = string.Empty;
    public int Port { get; init; }
    public string Username { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string VirtualHost { get; init; } = string.Empty;

    public static RabbitMqOptions From(IConfiguration configuration) => new()
    {
        Host = configuration.GetRequired("RABBITMQ_HOST"),
        Port = configuration.GetRequiredInt("RABBITMQ_PORT"),
        Username = configuration.GetRequired("RABBITMQ_USER"),
        Password = configuration.GetRequired("RABBITMQ_PASS"),
        VirtualHost = configuration.GetRequired("RABBITMQ_VHOST")
    };
}

public class JwtOptions
{
    public string Secret { get; init; } = string.Empty;
    public string Issuer { get; init; } = string.Empty;
    public string Audience { get; init; } = string.Empty;
    public int ExpiryMinutes { get; init; }

    public static JwtOptions From(IConfiguration configuration) => new()
    {
        Secret = configuration.GetRequired("JWT_SECRET"),
        Issuer = configuration.GetRequired("JWT_ISSUER"),
        Audience = configuration.GetRequired("JWT_AUDIENCE"),
        ExpiryMinutes = configuration.GetRequiredInt("JWT_EXPIRY_MINUTES")
    };
}

public class FileStorageOptions
{
    public string RootPath { get; init; } = string.Empty;

    public static FileStorageOptions From(IConfiguration configuration) => new()
    {
        RootPath = Path.GetFullPath(configuration.GetRequired("FILE_STORAGE_PATH"))
    };
}

public class AuthRateLimitOptions
{
    public int PermitLimit { get; init; }
    public TimeSpan Window { get; init; }

    public static AuthRateLimitOptions From(IConfiguration configuration) => new()
    {
        PermitLimit = configuration.GetRequiredInt("AUTH_RATE_LIMIT_PERMITS"),
        Window = TimeSpan.FromSeconds(configuration.GetRequiredInt("AUTH_RATE_LIMIT_WINDOW_SECONDS"))
    };
}

public class PolarOptions
{
    public string ApiUrl { get; init; } = string.Empty;
    public string AccessToken { get; init; } = string.Empty;
    public string ProductId { get; init; } = string.Empty;
    public string SuccessUrl { get; init; } = string.Empty;

    public static PolarOptions From(IConfiguration configuration) => new()
    {
        ApiUrl = configuration.GetRequired("POLAR_API_URL"),
        AccessToken = configuration.GetRequired("POLAR_ACCESS_TOKEN"),
        ProductId = configuration.GetRequired("POLAR_PRODUCT_ID"),
        SuccessUrl = configuration.GetRequired("POLAR_SUCCESS_URL")
    };
}

public class PasswordResetOptions
{
    public int CodeLifetimeMinutes { get; init; }

    public static PasswordResetOptions From(IConfiguration configuration) => new()
    {
        CodeLifetimeMinutes = configuration.GetRequiredInt("PASSWORD_RESET_CODE_MINUTES")
    };
}
