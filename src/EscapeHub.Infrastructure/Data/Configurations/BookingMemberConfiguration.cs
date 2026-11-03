using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data.Configurations;

public class BookingMemberConfiguration : IEntityTypeConfiguration<BookingMember>
{
    public void Configure(EntityTypeBuilder<BookingMember> builder)
    {
        builder.Property(m => m.ParticipantName).HasMaxLength(200).IsRequired();

        builder.HasOne(m => m.Booking)
            .WithMany(b => b.BookingMembers)
            .HasForeignKey(m => m.BookingId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
