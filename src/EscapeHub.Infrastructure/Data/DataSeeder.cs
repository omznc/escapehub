using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Infrastructure.Data;

public partial class DataSeeder
{
    private const string Password = "test";
    private const string FilesUrl = "/api/files/";
    private static readonly string ImageFolder = Path.Combine(AppContext.BaseDirectory, "Seed", "Images");

    private static readonly SeedUser[] Users =
    [
        new("desktop", "desktop@escapehub.ba", "Desktop", "Admin", Roles.Administrator, "Sarajevo", null),
        new("administrator", "admin@escapehub.ba", "Amina", "Hodzic", Roles.Administrator, "Sarajevo", "avatar-1.jpg"),
        new("zavala", "zavala@vanguard.com", "Commander", "Zavala", Roles.Administrator, "Sarajevo", null),
        new("roommanager", "manager@escapehub.ba", "Mirza", "Kovacevic", Roles.RoomManager, "Sarajevo", "avatar-2.jpg"),
        new("ikora", "ikora@hidden.net", "Ikora", "Rey", Roles.RoomManager, "Mostar", null),
        new("eris", "eris@hidden.net", "Eris", "Morn", Roles.RoomManager, "Zagreb", null),
        new("mobile", "mobile@escapehub.ba", "Lejla", "Begic", Roles.Client, "Sarajevo", "avatar-3.jpg"),
        new("client", "client@escapehub.ba", "Haris", "Delic", Roles.Client, "Mostar", "avatar-4.jpg"),
        new("cayde6", "cayde@lastcity.com", "Cayde", "Six", Roles.Client, "Sarajevo", null),
        new("alanwake", "alan@darkplace.com", "Alan", "Wake", Roles.Client, "Zagreb", null),
        new("sagaanderson", "saga@fbi.gov", "Saga", "Anderson", Roles.Client, "Belgrade", null),
        new("drifter", "drifter@gambit.com", "The", "Drifter", Roles.Client, "Mostar", null),
        new("osiris", "osiris@mercury.net", "Osiris", "Sagira", Roles.Client, "Split", null),
        new("saint14", "saint@tower.net", "Saint", "Fourteen", Roles.Client, "Tuzla", null),
        new("tor", "tor@cauldron.net", "Tor", "Anderson", Roles.Client, "Banja Luka", null)
    ];

    private readonly AppDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<ApplicationRole> _roleManager;
    private readonly IFileStorageService _storage;
    private readonly BusinessClock _clock;
    private readonly ILogger<DataSeeder> _logger;

    public DataSeeder(AppDbContext db, UserManager<ApplicationUser> userManager, RoleManager<ApplicationRole> roleManager,
        IFileStorageService storage, BusinessClock clock, ILogger<DataSeeder> logger)
    {
        _db = db;
        _userManager = userManager;
        _roleManager = roleManager;
        _storage = storage;
        _clock = clock;
        _logger = logger;
    }

    public async Task SeedAsync()
    {
        await SeedRolesAsync();
        await SeedReferenceDataAsync();
        await SeedSettingsAsync();
        await SeedUsersAsync();
        if (await _db.Rooms.AnyAsync()) return;

        await using var transaction = await _db.Database.BeginTransactionAsync();
        await SeedContentAsync();
        await transaction.CommitAsync();
        _logger.LogInformation("Seeded the demo content");
    }

    private async Task SeedRolesAsync()
    {
        foreach (var role in Roles.All)
        {
            if (!await _roleManager.RoleExistsAsync(role))
                await _roleManager.CreateAsync(new ApplicationRole(role));
        }
    }

    private async Task SeedReferenceDataAsync()
    {
        if (await _db.Countries.AnyAsync()) return;

        await using var transaction = await _db.Database.BeginTransactionAsync();
        var bosnia = new Country { Name = "Bosnia and Herzegovina" };
        var croatia = new Country { Name = "Croatia" };
        var serbia = new Country { Name = "Serbia" };
        _db.Cities.AddRange(
            new City { Name = "Sarajevo", Country = bosnia },
            new City { Name = "Mostar", Country = bosnia },
            new City { Name = "Banja Luka", Country = bosnia },
            new City { Name = "Tuzla", Country = bosnia },
            new City { Name = "Zagreb", Country = croatia },
            new City { Name = "Split", Country = croatia },
            new City { Name = "Belgrade", Country = serbia },
            new City { Name = "Novi Sad", Country = serbia });

        _db.Themes.AddRange(new[] { "Horror", "Adventure", "Mystery", "Sci-Fi", "Fantasy", "Historical" }.Select(n => new Theme { Name = n }));
        _db.DifficultyLevels.AddRange(
            new DifficultyLevel { Name = "Easy", Value = 1 },
            new DifficultyLevel { Name = "Medium", Value = 2 },
            new DifficultyLevel { Name = "Hard", Value = 3 },
            new DifficultyLevel { Name = "Expert", Value = 4 });
        _db.PromotionTypes.AddRange(
            new PromotionType { Name = "Percentage", IsPercentage = true },
            new PromotionType { Name = "Fixed amount", IsPercentage = false });
        _db.RewardTypes.AddRange(
            new RewardType { Name = "Percentage discount", IsPercentage = true },
            new RewardType { Name = "Fixed discount", IsPercentage = false });
        await _db.SaveChangesAsync();

        foreach (var status in Enum.GetValues<BookingStatusEnum>().Order())
        {
            _db.BookingStatuses.Add(new BookingStatus { Name = status == BookingStatusEnum.NoShow ? "No-show" : status.ToString() });
            await _db.SaveChangesAsync();
        }
        await transaction.CommitAsync();
    }

    private async Task SeedSettingsAsync()
    {
        if (await _db.SystemSettings.AnyAsync()) return;

        _db.SystemSettings.Add(new SystemSetting
        {
            CompanyName = "EscapeHub",
            ContactEmail = "info@escapehub.ba",
            ContactPhone = "+387 33 555 100",
            PointsPerPlayer = 10,
            PointsPerCurrencyUnit = 0.5m,
            CancellationDeadlineHours = 24,
            ReminderHoursBefore = 24
        });
        await _db.SaveChangesAsync();
    }

    private async Task SeedUsersAsync()
    {
        var cities = await _db.Cities.ToDictionaryAsync(c => c.Name, c => c.Id);
        await using var transaction = await _db.Database.BeginTransactionAsync();
        for (var i = 0; i < Users.Length; i++)
        {
            var seed = Users[i];
            if (await _userManager.FindByNameAsync(seed.UserName) != null) continue;

            var user = new ApplicationUser
            {
                UserName = seed.UserName,
                Email = seed.Email,
                EmailConfirmed = true,
                FirstName = seed.FirstName,
                LastName = seed.LastName,
                PhoneNumber = $"+387 61 {100 + i:000} {200 + i * 7:000}",
                CityId = cities[seed.City],
                IsActive = true
            };
            EnsureSucceeded(await _userManager.CreateAsync(user, Password), seed.UserName);
            EnsureSucceeded(await _userManager.AddToRoleAsync(user, seed.Role), seed.UserName);

            if (seed.Avatar == null) continue;
            user.ProfilePictureUrl = await StoreImageAsync($"profiles/{user.Id}/{seed.Avatar}", seed.Avatar);
            EnsureSucceeded(await _userManager.UpdateAsync(user), seed.UserName);
        }
        await transaction.CommitAsync();
    }

    private async Task<string> StoreImageAsync(string key, string fileName)
    {
        await using var file = File.OpenRead(Path.Combine(ImageFolder, fileName));
        await _storage.SaveAsync(key, file);
        return FilesUrl + key;
    }

    private static void EnsureSucceeded(IdentityResult result, string userName)
    {
        if (!result.Succeeded)
            throw new InvalidOperationException($"Seeding user {userName} failed: {string.Join(" ", result.Errors.Select(e => e.Description))}");
    }

    private record SeedUser(string UserName, string Email, string FirstName, string LastName, string Role, string City, string? Avatar);
}
