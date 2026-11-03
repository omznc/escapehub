using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reference;
using EscapeHub.Application.Exceptions;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Services.Reference;

public class ThemeService : ReferenceService<Theme, ReferenceDto, ReferenceRequest>
{
    public ThemeService(AppDbContext db, IMemoryCache cache, ILogger<ThemeService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "theme";
    protected override (string One, string Many) UsageNames => ("room", "rooms");
    protected override Expression<Func<Theme, int>> Usage => t => t.Rooms.Count();

    protected override Expression<Func<Theme, ReferenceDto>> Projection =>
        t => new ReferenceDto { Id = t.Id, Name = t.Name, UsageCount = t.Rooms.Count() };

    protected override void Apply(Theme entity, ReferenceRequest request) => entity.Name = request.Name.Trim();
}

public class CountryService : ReferenceService<Country, ReferenceDto, ReferenceRequest>
{
    public CountryService(AppDbContext db, IMemoryCache cache, ILogger<CountryService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "country";
    protected override (string One, string Many) UsageNames => ("city", "cities");
    protected override Expression<Func<Country, int>> Usage => c => c.Cities.Count();

    protected override Expression<Func<Country, ReferenceDto>> Projection =>
        c => new ReferenceDto { Id = c.Id, Name = c.Name, UsageCount = c.Cities.Count() };

    protected override void Apply(Country entity, ReferenceRequest request) => entity.Name = request.Name.Trim();
}

public class CityService : ReferenceService<City, CityDto, CityRequest>
{
    public CityService(AppDbContext db, IMemoryCache cache, ILogger<CityService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "city";
    protected override (string One, string Many) UsageNames => ("room or user", "rooms and users");
    protected override Expression<Func<City, int>> Usage => c => c.Rooms.Count() + c.Users.Count();

    protected override Expression<Func<City, CityDto>> Projection => c => new CityDto
    {
        Id = c.Id,
        Name = c.Name,
        CountryId = c.CountryId,
        CountryName = c.Country.Name,
        UsageCount = c.Rooms.Count() + c.Users.Count()
    };

    protected override IQueryable<City> Filter(IQueryable<City> entities, SortedQuery query) =>
        query is CityQuery { CountryId: { } countryId } ? entities.Where(c => c.CountryId == countryId) : entities;

    protected override async Task ValidateAsync(CityRequest request, int? id)
    {
        if (!await Db.Countries.AnyAsync(c => c.Id == request.CountryId))
            throw new BusinessException("Select a country from the list.", "countryId");
        await EnsureUniqueAsync(c => c.Name == request.Name.Trim() && c.CountryId == request.CountryId && c.Id != id);
    }

    protected override void Apply(City entity, CityRequest request)
    {
        entity.Name = request.Name.Trim();
        entity.CountryId = request.CountryId;
    }
}

public class DifficultyLevelService : ReferenceService<DifficultyLevel, DifficultyLevelDto, DifficultyLevelRequest>
{
    public DifficultyLevelService(AppDbContext db, IMemoryCache cache, ILogger<DifficultyLevelService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "difficulty level";
    protected override (string One, string Many) UsageNames => ("room or scenario", "rooms and scenarios");

    protected override Expression<Func<DifficultyLevel, int>> Usage =>
        d => d.Rooms.Count() + Db.RoomScenarios.Count(s => s.DifficultyOverrideId == d.Id);

    protected override Expression<Func<DifficultyLevel, DifficultyLevelDto>> Projection => d => new DifficultyLevelDto
    {
        Id = d.Id,
        Name = d.Name,
        Value = d.Value,
        UsageCount = d.Rooms.Count() + Db.RoomScenarios.Count(s => s.DifficultyOverrideId == d.Id)
    };

    protected override void Apply(DifficultyLevel entity, DifficultyLevelRequest request)
    {
        entity.Name = request.Name.Trim();
        entity.Value = request.Value;
    }
}

public class BookingStatusService : ReferenceService<BookingStatus, ReferenceDto, ReferenceRequest>
{
    public BookingStatusService(AppDbContext db, IMemoryCache cache, ILogger<BookingStatusService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "booking status";
    protected override (string One, string Many) UsageNames => ("booking", "bookings");
    protected override Expression<Func<BookingStatus, int>> Usage => s => s.Bookings.Count();

    protected override Expression<Func<BookingStatus, ReferenceDto>> Projection =>
        s => new ReferenceDto { Id = s.Id, Name = s.Name, UsageCount = s.Bookings.Count() };

    protected override string? DeleteBlockedReason(int id, int usageCount) =>
        Enum.IsDefined(typeof(BookingStatusEnum), id)
            ? "This booking status is used by the booking workflow and cannot be deleted."
            : base.DeleteBlockedReason(id, usageCount);

    protected override void Apply(BookingStatus entity, ReferenceRequest request) => entity.Name = request.Name.Trim();
}

public class PromotionTypeService : ReferenceService<PromotionType, DiscountTypeDto, DiscountTypeRequest>
{
    public PromotionTypeService(AppDbContext db, IMemoryCache cache, ILogger<PromotionTypeService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "promotion type";
    protected override (string One, string Many) UsageNames => ("promotion", "promotions");
    protected override Expression<Func<PromotionType, int>> Usage => t => t.Promotions.Count();

    protected override Expression<Func<PromotionType, DiscountTypeDto>> Projection => t => new DiscountTypeDto
    {
        Id = t.Id,
        Name = t.Name,
        IsPercentage = t.IsPercentage,
        UsageCount = t.Promotions.Count()
    };

    protected override void Apply(PromotionType entity, DiscountTypeRequest request)
    {
        entity.Name = request.Name.Trim();
        entity.IsPercentage = request.IsPercentage;
    }
}

public class RewardTypeService : ReferenceService<RewardType, DiscountTypeDto, DiscountTypeRequest>
{
    public RewardTypeService(AppDbContext db, IMemoryCache cache, ILogger<RewardTypeService> logger) : base(db, cache, logger) { }

    protected override string EntityName => "reward type";
    protected override (string One, string Many) UsageNames => ("reward", "rewards");
    protected override Expression<Func<RewardType, int>> Usage => t => t.LoyaltyRewards.Count();

    protected override Expression<Func<RewardType, DiscountTypeDto>> Projection => t => new DiscountTypeDto
    {
        Id = t.Id,
        Name = t.Name,
        IsPercentage = t.IsPercentage,
        UsageCount = t.LoyaltyRewards.Count()
    };

    protected override void Apply(RewardType entity, DiscountTypeRequest request)
    {
        entity.Name = request.Name.Trim();
        entity.IsPercentage = request.IsPercentage;
    }
}
