using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data;

public class AppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, int>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Room> Rooms => Set<Room>();
    public DbSet<RoomScenario> RoomScenarios => Set<RoomScenario>();
    public DbSet<Schedule> Schedules => Set<Schedule>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<BookingMember> BookingMembers => Set<BookingMember>();
    public DbSet<BookingStatusHistory> BookingStatusHistory => Set<BookingStatusHistory>();
    public DbSet<RoomResult> RoomResults => Set<RoomResult>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<LoyaltyTransaction> LoyaltyTransactions => Set<LoyaltyTransaction>();
    public DbSet<LoyaltyReward> LoyaltyRewards => Set<LoyaltyReward>();
    public DbSet<RewardRedemption> RewardRedemptions => Set<RewardRedemption>();
    public DbSet<Promotion> Promotions => Set<Promotion>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<SystemSetting> SystemSettings => Set<SystemSetting>();
    public DbSet<PasswordResetCode> PasswordResetCodes => Set<PasswordResetCode>();
    public DbSet<Theme> Themes => Set<Theme>();
    public DbSet<DifficultyLevel> DifficultyLevels => Set<DifficultyLevel>();
    public DbSet<BookingStatus> BookingStatuses => Set<BookingStatus>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<PromotionType> PromotionTypes => Set<PromotionType>();
    public DbSet<RewardType> RewardTypes => Set<RewardType>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }

    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        ApplyAuditFields();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        ApplyAuditFields();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    private void ApplyAuditFields()
    {
        var now = DateTime.UtcNow;
        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.State is not (EntityState.Added or EntityState.Modified)) continue;

            switch (entry.Entity)
            {
                case BaseEntity entity:
                    Stamp(entry.State, now, () => entity.CreatedAt, v => entity.CreatedAt = v, v => entity.UpdatedAt = v);
                    break;
                case ApplicationUser user:
                    Stamp(entry.State, now, () => user.CreatedAt, v => user.CreatedAt = v, v => user.UpdatedAt = v);
                    break;
            }
        }
    }

    private static void Stamp(EntityState state, DateTime now, Func<DateTime> getCreated, Action<DateTime> setCreated, Action<DateTime> setUpdated)
    {
        if (state == EntityState.Added && getCreated() == default)
            setCreated(now);
        setUpdated(now);
    }
}
