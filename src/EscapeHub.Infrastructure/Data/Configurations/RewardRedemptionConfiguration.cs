using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class RewardRedemptionConfiguration : IEntityTypeConfiguration<RewardRedemption>
{
    public void Configure(EntityTypeBuilder<RewardRedemption> builder)
    {
        builder.Property(r => r.Code).HasMaxLength(50).IsRequired();
        builder.Property(r => r.PointsSpent).IsRequired();
        builder.Property(r => r.Value).HasColumnType("decimal(10,2)");
        builder.Property(r => r.IsUsed).HasDefaultValue(false);
        builder.HasIndex(r => r.Code).IsUnique();

        builder.HasOne(r => r.Client)
            .WithMany(u => u.RewardRedemptions)
            .HasForeignKey(r => r.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.LoyaltyReward)
            .WithMany(lr => lr.RewardRedemptions)
            .HasForeignKey(r => r.LoyaltyRewardId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.Booking)
            .WithOne(b => b.RewardRedemption)
            .HasForeignKey<RewardRedemption>(r => r.BookingId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
