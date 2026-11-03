using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class RoomConfiguration : IEntityTypeConfiguration<Room>
{
    public void Configure(EntityTypeBuilder<Room> builder)
    {
        builder.Property(r => r.Name).HasMaxLength(200).IsRequired();
        builder.Property(r => r.ShortDescription).HasMaxLength(500).IsRequired();
        builder.Property(r => r.LongDescription).HasMaxLength(2000).IsRequired();
        builder.Property(r => r.MinPlayers).IsRequired();
        builder.Property(r => r.MaxPlayers).IsRequired();
        builder.Property(r => r.DurationMinutes).IsRequired();
        builder.Property(r => r.PricePerPerson).HasColumnType("decimal(10,2)");
        builder.Property(r => r.PricePerBooking).HasColumnType("decimal(10,2)");
        builder.Property(r => r.ImageUrl).HasMaxLength(500);
        builder.Property(r => r.IsActive).HasDefaultValue(true);
        builder.Property(r => r.AgeRecommendation).HasMaxLength(100);
        builder.HasIndex(r => r.Name).IsUnique().HasFilter("[IsDeleted] = 0");
        builder.HasQueryFilter(r => !r.IsDeleted);
        builder.ToTable(t => t.HasCheckConstraint("CK_Rooms_Players", "[MinPlayers] >= 1 AND [MaxPlayers] >= [MinPlayers]"));

        builder.HasOne(r => r.Theme)
            .WithMany(t => t.Rooms)
            .HasForeignKey(r => r.ThemeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.DifficultyLevel)
            .WithMany(d => d.Rooms)
            .HasForeignKey(r => r.DifficultyLevelId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.City)
            .WithMany(c => c.Rooms)
            .HasForeignKey(r => r.CityId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.Manager)
            .WithMany(u => u.ManagedRooms)
            .HasForeignKey(r => r.ManagerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
