using Equipify.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace Equipify.Data;

/// <summary>EF Core code-first database context for Equipify.</summary>
public class EquipifyDbContext : DbContext
{
    public EquipifyDbContext(DbContextOptions<EquipifyDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<ListingImage> ListingImages => Set<ListingImage>();
    public DbSet<RentalRequest> RentalRequests => Set<RentalRequest>();
    public DbSet<UserRating> UserRatings => Set<UserRating>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
