using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class RoomScenarioConfiguration : IEntityTypeConfiguration<RoomScenario>
{
    public void Configure(EntityTypeBuilder<RoomScenario> builder)
    {
        builder.Property(s => s.Name).HasMaxLength(200).IsRequired();
        builder.Property(s => s.Story).HasMaxLength(2000).IsRequired();
        builder.Property(s => s.HintPolicy).HasMaxLength(500);
        builder.Property(s => s.IsActive).HasDefaultValue(true);

        builder.HasOne(s => s.Room)
            .WithMany(r => r.Scenarios)
            .HasForeignKey(s => s.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.DifficultyOverride)
            .WithMany()
            .HasForeignKey(s => s.DifficultyOverrideId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
