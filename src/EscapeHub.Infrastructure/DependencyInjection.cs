using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Identity;
using EscapeHub.Infrastructure.Messaging;
using EscapeHub.Infrastructure.Services;
using EscapeHub.Infrastructure.Services.Reference;
using EscapeHub.Infrastructure.Storage;

namespace EscapeHub.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString();
        services.AddDbContext<AppDbContext>(options => options.UseSqlServer(connectionString)
            .ConfigureWarnings(warnings => warnings.Ignore(CoreEventId.PossibleIncorrectRequiredNavigationWithQueryFilterInteractionWarning)));
        services.AddSingleton(RabbitMqOptions.From(configuration));
        services.AddSingleton(BusinessClock.From(configuration));
        return services;
    }

    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddPersistence(configuration);
        services.AddMemoryCache();
        services.AddSingleton(JwtOptions.From(configuration));
        services.AddSingleton(FileStorageOptions.From(configuration));
        services.AddSingleton(PasswordResetOptions.From(configuration));
        services.AddSingleton<IEventPublisher, EventPublisher>();
        services.AddSingleton<IFileStorageService, LocalFileStorage>();

        services.AddScoped<DataSeeder>();
        services.AddScoped<SessionValidator>();
        services.AddScoped<RoomAccess>();
        services.AddScoped<SettingsService>();
        services.AddScoped<AuthService>();
        services.AddScoped<UserService>();
        services.AddScoped<RoomService>();
        services.AddScoped<RoomScenarioService>();
        services.AddScoped<ScheduleService>();
        services.AddScoped<BookingService>();
        services.AddScoped<BookingWorkflowService>();
        services.AddScoped<PromotionService>();
        services.AddScoped<LoyaltyService>();
        services.AddScoped<ReviewService>();
        services.AddScoped<NotificationService>();
        services.AddScoped<FileService>();
        services.AddScoped<ReportService>();
        services.AddScoped<DashboardService>();
        services.AddScoped<RecommendationService>();

        services.AddScoped<ThemeService>();
        services.AddScoped<DifficultyLevelService>();
        services.AddScoped<BookingStatusService>();
        services.AddScoped<CountryService>();
        services.AddScoped<CityService>();
        services.AddScoped<PromotionTypeService>();
        services.AddScoped<RewardTypeService>();
        return services;
    }
}
