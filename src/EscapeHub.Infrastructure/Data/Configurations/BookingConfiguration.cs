using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class BookingConfiguration : IEntityTypeConfiguration<Booking>
{
    public void Configure(EntityTypeBuilder<Booking> builder)
    {
        builder.Property(b => b.Subtotal).HasColumnType("decimal(10,2)");
        builder.Property(b => b.TotalPrice).HasColumnType("decimal(10,2)");
        builder.Property(b => b.DiscountApplied).HasColumnType("decimal(10,2)").HasDefaultValue(0m);
        builder.Property(b => b.PlayerCount).IsRequired();
        builder.Property(b => b.Notes).HasMaxLength(1000);

        builder.HasOne(b => b.Schedule)
            .WithMany(s => s.Bookings)
            .HasForeignKey(b => b.ScheduleId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(b => b.ScheduleId)
            .IsUnique()
            .HasFilter($"[BookingStatusId] <> {(int)BookingStatusEnum.Cancelled} AND [BookingStatusId] <> {(int)BookingStatusEnum.Rejected}");

        builder.HasOne(b => b.Client)
            .WithMany(u => u.Bookings)
            .HasForeignKey(b => b.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.BookingStatus)
            .WithMany(bs => bs.Bookings)
            .HasForeignKey(b => b.BookingStatusId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.Promotion)
            .WithMany(p => p.Bookings)
            .HasForeignKey(b => b.PromotionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
