using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class BookingStatusHistoryConfiguration : IEntityTypeConfiguration<BookingStatusHistory>
{
    public void Configure(EntityTypeBuilder<BookingStatusHistory> builder)
    {
        builder.ToTable("BookingStatusHistory");
        builder.Property(h => h.Reason).HasMaxLength(500);

        builder.HasOne(h => h.Booking)
            .WithMany(b => b.StatusHistory)
            .HasForeignKey(h => h.BookingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(h => h.FromStatus)
            .WithMany()
            .HasForeignKey(h => h.FromStatusId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(h => h.ToStatus)
            .WithMany()
            .HasForeignKey(h => h.ToStatusId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(h => h.ChangedBy)
            .WithMany()
            .HasForeignKey(h => h.ChangedById)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
