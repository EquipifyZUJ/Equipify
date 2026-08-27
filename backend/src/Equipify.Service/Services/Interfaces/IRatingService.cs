using Equipify.Domain.Entities;
using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface IRatingService
{
    /// <summary>Submits a renter's rating for a completed rental request and
    /// recalculates the owner's average rating.</summary>
    Task<ServiceResult> SubmitAsync(int renterId, int rentalRequestId, double rating);

    /// <summary>Returns all reviews left for a given user (as owner).</summary>
    Task<List<UserRating>> GetReviewsForUserAsync(int userId, int limit = 20);

    /// <summary>Returns all reviews left for a given listing.</summary>
    Task<List<UserRating>> GetReviewsForListingAsync(int listingId, int limit = 20);
}
