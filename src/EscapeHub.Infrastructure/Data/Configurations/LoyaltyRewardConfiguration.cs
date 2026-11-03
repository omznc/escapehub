using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class LoyaltyRewardConfiguration : IEntityTypeConfiguration<LoyaltyReward>
{
    public void Configure(EntityTypeBuilder<LoyaltyReward> builder)
    {
        builder.Property(r => r.Name).HasMaxLength(200).IsRequired();
        builder.Property(r => r.Description).HasMaxLength(1000).IsRequired();
        builder.Property(r => r.PointsCost).IsRequired();
        builder.Property(r => r.Value).HasColumnType("decimal(10,2)");
        builder.Property(r => r.IsActive).HasDefaultValue(true);

        builder.HasOne(r => r.RewardType)
            .WithMany(rt => rt.LoyaltyRewards)
            .HasForeignKey(r => r.RewardTypeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
