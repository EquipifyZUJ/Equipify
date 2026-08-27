using Equipify.Data.Repositories;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;

namespace Equipify.Service.Services;

public class DashboardService : IDashboardService
{
    private readonly IUnitOfWork _uow;

    public DashboardService(IUnitOfWork uow) => _uow = uow;

    public async Task<DashboardStats> GetStatsAsync() => new()
    {
        Users = await _uow.Users.CountAsync(),
        Listings = await _uow.Listings.CountAsync(),
        ActiveListings = await _uow.Listings.CountAsync(l => l.Status == ListingStatus.Active),
        PendingListings = await _uow.Listings.CountAsync(l => l.Status == ListingStatus.Pending),
        Categories = await _uow.Categories.CountAsync(),
        Requests = await _uow.RentalRequests.CountAsync(),
        PendingRequests = await _uow.RentalRequests.CountAsync(r => r.Status == RequestStatus.Pending)
    };
}
