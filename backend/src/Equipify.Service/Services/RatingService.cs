using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Equipify.Service.Services;

public class RatingService : IRatingService
{
    private readonly IUnitOfWork _uow;

    public RatingService(IUnitOfWork uow) => _uow = uow;

    public async Task<ServiceResult> SubmitAsync(int renterId, int rentalRequestId, double rating)
    {
        if (rating < 1 || rating > 5)
            return ServiceResult.Fail("Rating must be between 1 and 5.");

        var request = await _uow.RentalRequests.Query()
            .Include(r => r.Listing)
            .FirstOrDefaultAsync(r => r.Id == rentalRequestId);

        if (request is null) return ServiceResult.Fail("Rental request not found.");
        if (request.UserId != renterId)
            return ServiceResult.Fail("You can only rate your own rentals.");
        if (request.Status != RequestStatus.Accepted)
            return ServiceResult.Fail("You can only rate accepted rentals.");
        if (await _uow.UserRatings.AnyAsync(r => r.RentalRequestId == rentalRequestId))
            return ServiceResult.Fail("You have already rated this rental.");

        int ownerId = request.Listing!.OwnerId;

        await _uow.UserRatings.AddAsync(new UserRating
        {
            RenterId = renterId,
            OwnerId = ownerId,
            ListingId = request.ListingId,
            RentalRequestId = rentalRequestId,
            Rating = rating
        });
        await _uow.SaveChangesAsync();

        // Recalculate owner's average rating.
        var ownerRatings = await _uow.UserRatings.Query()
            .Where(r => r.OwnerId == ownerId)
            .Select(r => r.Rating)
            .ToListAsync();

        var owner = await _uow.Users.GetByIdAsync(ownerId);
        if (owner is not null)
        {
            owner.Rating = Math.Round(ownerRatings.Average(), 2);
            _uow.Users.Update(owner);
            await _uow.SaveChangesAsync();
        }

        return ServiceResult.Ok();
    }

    public Task<List<UserRating>> GetReviewsForUserAsync(int userId, int limit = 20)
        => _uow.UserRatings.Query()
            .AsNoTracking()
            .Include(r => r.Renter)
            .Include(r => r.Listing)
            .Where(r => r.OwnerId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Take(Math.Clamp(limit, 1, 50))
            .ToListAsync();

    public Task<List<UserRating>> GetReviewsForListingAsync(int listingId, int limit = 20)
        => _uow.UserRatings.Query()
            .AsNoTracking()
            .Include(r => r.Renter)
            .Where(r => r.ListingId == listingId)
            .OrderByDescending(r => r.CreatedAt)
            .Take(Math.Clamp(limit, 1, 50))
            .ToListAsync();
}
