using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
{
    public void Configure(EntityTypeBuilder<Payment> builder)
    {
        builder.Property(p => p.CheckoutId).HasMaxLength(100).IsRequired();
        builder.Property(p => p.CheckoutUrl).HasMaxLength(500).IsRequired();
        builder.Property(p => p.Amount).HasColumnType("decimal(10,2)");
        builder.Property(p => p.Currency).HasMaxLength(3).IsRequired();
        builder.Property(p => p.OrderId).HasMaxLength(100);
        builder.HasIndex(p => p.CheckoutId).IsUnique();
        builder.HasIndex(p => p.BookingId).IsUnique().HasFilter("[Status] IN (1, 2)");

        builder.HasOne(p => p.Booking)
            .WithMany(b => b.Payments)
            .HasForeignKey(p => p.BookingId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
