using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface IListingService
{
    /// <summary>Public browse with Airbnb-style filters (search, category, price range,
    /// map viewport bounds) and pagination. Only Active listings are returned.</summary>
    Task<PagedResult<Listing>> BrowseAsync(ListingFilterDto filter);

    /// <summary>Details of a listing; pass includeInactive for owner/admin views.</summary>
    Task<Listing?> GetDetailsAsync(int id, bool includeInactive = false);

    /// <summary>Lightweight list for map markers within a viewport.</summary>
    Task<List<Listing>> GetForMapAsync(double west, double south, double east, double north, int? categoryId = null, string? search = null);

    Task<List<Listing>> GetByOwnerAsync(int ownerId);
    Task<List<Listing>> GetAllAsync();

    Task<ServiceResult<int>> CreateAsync(ListingInputDto dto);

    /// <summary>Owner edits return the listing to Pending (re-approval); admin edits keep status.</summary>
    Task<ServiceResult> UpdateAsync(ListingInputDto dto, bool isAdmin = false);

    Task<ServiceResult> SetStatusAsync(int id, ListingStatus status, int? ownerId = null);
    Task<ServiceResult> DeleteAsync(int id, int? ownerId = null);
}
