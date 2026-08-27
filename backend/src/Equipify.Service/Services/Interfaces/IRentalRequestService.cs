using Equipify.Domain.Entities;
using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface IRentalRequestService
{
    Task<ServiceResult<int>> CreateAsync(RentalRequestDto dto);

    /// <summary>Requests placed by a renter.</summary>
    Task<List<RentalRequest>> GetMyRequestsAsync(int userId);

    /// <summary>Requests placed against a specific listing owned by the owner.</summary>
    Task<List<RentalRequest>> GetRequestsForListingAsync(int listingId, int ownerId);

    /// <summary>All requests across every listing owned by the owner.</summary>
    Task<List<RentalRequest>> GetIncomingForOwnerAsync(int ownerId);

    Task<List<RentalRequest>> GetAllAsync();

    Task<ServiceResult> AcceptAsync(int requestId, int ownerId);
    Task<ServiceResult> RejectAsync(int requestId, int ownerId);
    Task<ServiceResult> DeleteAsync(int requestId, int? actingUserId = null, bool isAdmin = false);
}
