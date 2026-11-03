using DotNetEnv;
using Microsoft.Extensions.Configuration;

namespace EscapeHub.Infrastructure.Configuration;

public static class EnvironmentConfiguration
{
    public static void LoadDotEnv() => Env.NoClobber().TraversePath().Load();

    public static string GetRequired(this IConfiguration configuration, string key)
    {
        var value = configuration[key];
        if (string.IsNullOrWhiteSpace(value))
            throw new InvalidOperationException($"Configuration value '{key}' is missing. Set it in the .env file.");
        return value;
    }

    public static int GetRequiredInt(this IConfiguration configuration, string key) =>
        int.Parse(configuration.GetRequired(key));

    public static bool GetBool(this IConfiguration configuration, string key) =>
        bool.TryParse(configuration[key], out var value) && value;

    public static string GetConnectionString(this IConfiguration configuration) =>
        $"Server={configuration.GetRequired("SQLSERVER_HOST")},{configuration.GetRequired("SQLSERVER_PORT")};" +
        $"Database={configuration.GetRequired("SQLSERVER_DATABASE")};" +
        $"User Id={configuration.GetRequired("SQLSERVER_USER")};" +
        $"Password={configuration.GetRequired("SQLSERVER_SA_PASSWORD")};TrustServerCertificate=True;";
}
