using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Equipify.Data.Configurations;

public class ListingConfiguration : IEntityTypeConfiguration<Listing>
{
    public void Configure(EntityTypeBuilder<Listing> b)
    {
        b.ToTable("Listings");
        b.HasKey(l => l.Id);
        b.Property(l => l.Title).IsRequired().HasMaxLength(200);
        b.Property(l => l.Description).IsRequired();
        b.Property(l => l.MainImage).HasMaxLength(300);
        b.Property(l => l.LocationAddress).IsRequired().HasMaxLength(200);

        // Flexible pricing
        b.Property(l => l.CostPerHour).HasPrecision(12, 2);
        b.Property(l => l.CostPerDay).HasPrecision(12, 2);
        b.Property(l => l.CostPerWeek).HasPrecision(12, 2);
        b.Property(l => l.CostPerMonth).HasPrecision(12, 2);
        b.Property(l => l.CostPerYear).HasPrecision(12, 2);

        b.Property(l => l.Status).HasConversion<int>();

        b.HasMany(l => l.Images)
            .WithOne(i => i.Listing)
            .HasForeignKey(i => i.ListingId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasMany(l => l.RentalRequests)
            .WithOne(r => r.Listing)
            .HasForeignKey(r => r.ListingId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
