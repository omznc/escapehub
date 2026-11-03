using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class PromotionConfiguration : IEntityTypeConfiguration<Promotion>
{
    public void Configure(EntityTypeBuilder<Promotion> builder)
    {
        builder.Property(p => p.Name).HasMaxLength(200).IsRequired();
        builder.Property(p => p.Description).HasMaxLength(1000).IsRequired();
        builder.Property(p => p.DiscountValue).HasColumnType("decimal(10,2)");
        builder.Property(p => p.IsActive).HasDefaultValue(true);

        builder.HasOne(p => p.PromotionType)
            .WithMany(pt => pt.Promotions)
            .HasForeignKey(p => p.PromotionTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(p => p.Rooms)
            .WithMany(r => r.Promotions)
            .UsingEntity("PromotionRooms");
    }
}
