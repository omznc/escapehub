using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class SystemSettingConfiguration : IEntityTypeConfiguration<SystemSetting>
{
    public void Configure(EntityTypeBuilder<SystemSetting> builder)
    {
        builder.Property(s => s.CompanyName).HasMaxLength(200).IsRequired();
        builder.Property(s => s.ContactEmail).HasMaxLength(256).IsRequired();
        builder.Property(s => s.ContactPhone).HasMaxLength(30);
        builder.Property(s => s.PointsPerCurrencyUnit).HasColumnType("decimal(10,2)");

        builder.HasOne(s => s.UpdatedBy)
            .WithMany()
            .HasForeignKey(s => s.UpdatedById)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
