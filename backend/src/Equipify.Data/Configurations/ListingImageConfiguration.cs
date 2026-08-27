using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Equipify.Data.Configurations;

public class ListingImageConfiguration : IEntityTypeConfiguration<ListingImage>
{
    public void Configure(EntityTypeBuilder<ListingImage> b)
    {
        b.ToTable("ListingImages");
        b.HasKey(i => i.Id);
        b.Property(i => i.ImagePath).IsRequired().HasMaxLength(300);
    }
}
