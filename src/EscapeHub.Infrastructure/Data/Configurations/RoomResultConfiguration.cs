using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class RoomResultConfiguration : IEntityTypeConfiguration<RoomResult>
{
    public void Configure(EntityTypeBuilder<RoomResult> builder)
    {
        builder.Property(r => r.ManagerNotes).HasMaxLength(2000);

        builder.HasOne(r => r.Booking)
            .WithOne(b => b.RoomResult)
            .HasForeignKey<RoomResult>(r => r.BookingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.RecordedBy)
            .WithMany()
            .HasForeignKey(r => r.RecordedById)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
