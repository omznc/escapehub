using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.Property(r => r.Rating).IsRequired();
        builder.Property(r => r.Comment).HasMaxLength(2000);
        builder.Property(r => r.IsHidden).HasDefaultValue(false);
        builder.ToTable(t => t.HasCheckConstraint("CK_Reviews_Rating", "[Rating] BETWEEN 1 AND 5"));

        builder.HasOne(r => r.Room)
            .WithMany(rm => rm.Reviews)
            .HasForeignKey(r => r.RoomId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.Client)
            .WithMany(u => u.Reviews)
            .HasForeignKey(r => r.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(r => new { r.RoomId, r.ClientId }).IsUnique().HasFilter("[IsDeleted] = 0");
        builder.HasQueryFilter(r => !r.IsDeleted);
    }
}
