using Equipify.Domain.Entities;

namespace Equipify.Data.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly EquipifyDbContext _context;

    public UnitOfWork(EquipifyDbContext context)
    {
        _context = context;
        Users = new Repository<User>(context);
        Categories = new Repository<Category>(context);
        Listings = new Repository<Listing>(context);
        ListingImages = new Repository<ListingImage>(context);
        RentalRequests = new Repository<RentalRequest>(context);
        UserRatings = new Repository<UserRating>(context);
        RefreshTokens = new Repository<RefreshToken>(context);
    }

    public IRepository<User> Users { get; }
    public IRepository<Category> Categories { get; }
    public IRepository<Listing> Listings { get; }
    public IRepository<ListingImage> ListingImages { get; }
    public IRepository<RentalRequest> RentalRequests { get; }
    public IRepository<UserRating> UserRatings { get; }
    public IRepository<RefreshToken> RefreshTokens { get; }

    public Task<int> SaveChangesAsync() => _context.SaveChangesAsync();

    public void Dispose() => _context.Dispose();
}
