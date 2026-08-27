using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Equipify.Data.Configurations;

public class UserRatingConfiguration : IEntityTypeConfiguration<UserRating>
{
    public void Configure(EntityTypeBuilder<UserRating> b)
    {
        b.ToTable("UserRatings");
        b.HasKey(r => r.Id);

        // A renter may rate a given rental request only once.
        b.HasIndex(r => r.RentalRequestId).IsUnique();

        b.HasOne(r => r.Renter)
            .WithMany(u => u.RatingsGiven)
            .HasForeignKey(r => r.RenterId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne(r => r.Owner)
            .WithMany(u => u.RatingsReceived)
            .HasForeignKey(r => r.OwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne(r => r.Listing)
            .WithMany()
            .HasForeignKey(r => r.ListingId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
