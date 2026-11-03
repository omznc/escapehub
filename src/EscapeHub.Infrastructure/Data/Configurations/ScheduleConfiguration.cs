using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class ScheduleConfiguration : IEntityTypeConfiguration<Schedule>
{
    public void Configure(EntityTypeBuilder<Schedule> builder)
    {
        builder.Property(s => s.Date).HasColumnType("date");
        builder.Property(s => s.IsBlocked).HasDefaultValue(false);
        builder.Ignore(s => s.StartsAt);
        builder.ToTable(t => t.HasCheckConstraint("CK_Schedules_Time", "[EndTime] > [StartTime]"));

        builder.HasOne(s => s.Room)
            .WithMany(r => r.Schedules)
            .HasForeignKey(s => s.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => new { s.RoomId, s.Date, s.StartTime }).IsUnique();
    }
}
