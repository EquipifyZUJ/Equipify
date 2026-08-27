using Equipify.Domain.Entities;

namespace Equipify.Data.Repositories;

/// <summary>Coordinates repositories and commits changes in a single transaction.</summary>
public interface IUnitOfWork : IDisposable
{
    IRepository<User> Users { get; }
    IRepository<Category> Categories { get; }
    IRepository<Listing> Listings { get; }
    IRepository<ListingImage> ListingImages { get; }
    IRepository<RentalRequest> RentalRequests { get; }
    IRepository<UserRating> UserRatings { get; }
    IRepository<RefreshToken> RefreshTokens { get; }

    Task<int> SaveChangesAsync();
}
