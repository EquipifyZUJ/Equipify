using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Equipify.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.ToTable("Users");
        b.HasKey(u => u.Id);
        b.Property(u => u.FirstName).IsRequired().HasMaxLength(100);
        b.Property(u => u.LastName).IsRequired().HasMaxLength(100);
        b.Ignore(u => u.FullName); // Computed, not stored
        b.Property(u => u.EmailAddress).IsRequired().HasMaxLength(200);
        b.Property(u => u.PhoneNumber).IsRequired().HasMaxLength(20);
        b.Property(u => u.PasswordHash).IsRequired().HasMaxLength(200);
        b.Property(u => u.Status).HasConversion<int>();

        b.HasIndex(u => u.PhoneNumber).IsUnique();
        b.HasIndex(u => u.EmailAddress).IsUnique();

        b.HasMany(u => u.Listings)
            .WithOne(l => l.Owner)
            .HasForeignKey(l => l.OwnerId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasMany(u => u.RentalRequests)
            .WithOne(r => r.User)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
