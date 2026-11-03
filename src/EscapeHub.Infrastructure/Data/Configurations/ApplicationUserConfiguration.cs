using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        builder.Property(u => u.FirstName).HasMaxLength(100).IsRequired();
        builder.Property(u => u.LastName).HasMaxLength(100).IsRequired();
        builder.Property(u => u.Email).HasMaxLength(256).IsRequired();
        builder.Property(u => u.IsActive).HasDefaultValue(true);
        builder.Property(u => u.ProfilePictureUrl).HasMaxLength(500);

        builder.HasOne(u => u.City)
            .WithMany(c => c.Users)
            .HasForeignKey(u => u.CityId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
