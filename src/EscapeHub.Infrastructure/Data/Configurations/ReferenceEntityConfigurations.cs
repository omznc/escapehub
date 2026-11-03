using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class ThemeConfiguration : IEntityTypeConfiguration<Theme>
{
    public void Configure(EntityTypeBuilder<Theme> builder)
    {
        builder.Property(t => t.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(t => t.Name).IsUnique();
    }
}

public class DifficultyLevelConfiguration : IEntityTypeConfiguration<DifficultyLevel>
{
    public void Configure(EntityTypeBuilder<DifficultyLevel> builder)
    {
        builder.Property(d => d.Name).HasMaxLength(100).IsRequired();
        builder.Property(d => d.Value).IsRequired();
        builder.HasIndex(d => d.Name).IsUnique();
    }
}

public class BookingStatusConfiguration : IEntityTypeConfiguration<BookingStatus>
{
    public void Configure(EntityTypeBuilder<BookingStatus> builder)
    {
        builder.Property(b => b.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(b => b.Name).IsUnique();
    }
}

public class CountryConfiguration : IEntityTypeConfiguration<Country>
{
    public void Configure(EntityTypeBuilder<Country> builder)
    {
        builder.Property(c => c.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(c => c.Name).IsUnique();
    }
}

public class CityConfiguration : IEntityTypeConfiguration<City>
{
    public void Configure(EntityTypeBuilder<City> builder)
    {
        builder.Property(c => c.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(c => new { c.CountryId, c.Name }).IsUnique();

        builder.HasOne(c => c.Country)
            .WithMany(cn => cn.Cities)
            .HasForeignKey(c => c.CountryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class PromotionTypeConfiguration : IEntityTypeConfiguration<PromotionType>
{
    public void Configure(EntityTypeBuilder<PromotionType> builder)
    {
        builder.Property(p => p.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(p => p.Name).IsUnique();
    }
}

public class RewardTypeConfiguration : IEntityTypeConfiguration<RewardType>
{
    public void Configure(EntityTypeBuilder<RewardType> builder)
    {
        builder.Property(r => r.Name).HasMaxLength(100).IsRequired();
        builder.HasIndex(r => r.Name).IsUnique();
    }
}
