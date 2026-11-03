using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class LoyaltyTransactionConfiguration : IEntityTypeConfiguration<LoyaltyTransaction>
{
    public void Configure(EntityTypeBuilder<LoyaltyTransaction> builder)
    {
        builder.Property(t => t.Points).IsRequired();
        builder.Property(t => t.Description).HasMaxLength(500);

        builder.HasOne(t => t.Client)
            .WithMany(u => u.LoyaltyTransactions)
            .HasForeignKey(t => t.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.Booking)
            .WithMany(b => b.LoyaltyTransactions)
            .HasForeignKey(t => t.BookingId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.RewardRedemption)
            .WithMany()
            .HasForeignKey(t => t.RewardRedemptionId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(t => new { t.BookingId, t.TransactionType })
            .IsUnique()
            .HasFilter("[BookingId] IS NOT NULL");
    }
}
