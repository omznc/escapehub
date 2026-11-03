using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Worker.Configuration;

public class SmtpOptions
{
    public string Host { get; init; } = string.Empty;
    public int Port { get; init; }
    public string? Username { get; init; }
    public string? Password { get; init; }
    public bool UseSsl { get; init; }
    public string FromEmail { get; init; } = string.Empty;
    public string FromName { get; init; } = string.Empty;

    public static SmtpOptions From(IConfiguration configuration) => new()
    {
        Host = configuration.GetRequired("SMTP_HOST"),
        Port = configuration.GetRequiredInt("SMTP_PORT"),
        Username = configuration["SMTP_USERNAME"],
        Password = configuration["SMTP_PASSWORD"],
        UseSsl = configuration.GetBool("SMTP_USE_SSL"),
        FromEmail = configuration.GetRequired("SMTP_FROM_EMAIL"),
        FromName = configuration.GetRequired("SMTP_FROM_NAME")
    };
}

public class PointsSweepOptions
{
    public TimeSpan Interval { get; init; }

    public static PointsSweepOptions From(IConfiguration configuration) => new()
    {
        Interval = TimeSpan.FromSeconds(configuration.GetRequiredInt("POINTS_SWEEP_INTERVAL_SECONDS"))
    };
}

public class ReminderOptions
{
    public TimeSpan ScanInterval { get; init; }

    public static ReminderOptions From(IConfiguration configuration) => new()
    {
        ScanInterval = TimeSpan.FromSeconds(configuration.GetRequiredInt("REMINDER_SCAN_INTERVAL_SECONDS"))
    };
}
