using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Equipify.Data.Configurations;

public class RentalRequestConfiguration : IEntityTypeConfiguration<RentalRequest>
{
    public void Configure(EntityTypeBuilder<RentalRequest> b)
    {
        b.ToTable("RentalRequests");
        b.HasKey(r => r.Id);
        b.Property(r => r.Status).HasConversion<int>();
        b.Property(r => r.TotalCost).HasPrecision(12, 2);

        b.HasOne(r => r.Rating)
            .WithOne(ur => ur.RentalRequest)
            .HasForeignKey<UserRating>(ur => ur.RentalRequestId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
