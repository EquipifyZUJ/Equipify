using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Equipify.Service.Services;

public class RentalRequestService : IRentalRequestService
{
    private readonly IUnitOfWork _uow;
    private readonly IEmailService _email;
    private readonly ILogger<RentalRequestService> _logger;

    public RentalRequestService(IUnitOfWork uow, IEmailService email, ILogger<RentalRequestService> logger)
    {
        _uow = uow;
        _email = email;
        _logger = logger;
    }

    public async Task<ServiceResult<int>> CreateAsync(RentalRequestDto dto)
    {
        if (!dto.OtpVerified)
            return ServiceResult<int>.Fail("Please verify the OTP before submitting your request.");
        if (dto.FromDate > dto.ToDate)
            return ServiceResult<int>.Fail("The start date cannot be after the end date.");

        var listing = await _uow.Listings.GetByIdAsync(dto.ListingId);
        if (listing is null) return ServiceResult<int>.Fail("Listing not found.");
        if (listing.Status != ListingStatus.Active)
            return ServiceResult<int>.Fail("This listing is not available right now.");
        if (listing.OwnerId == dto.UserId)
            return ServiceResult<int>.Fail("You cannot request your own listing.");

        // Prevent double booking: overlap against pending/accepted requests.
        var hasConflict = await _uow.RentalRequests.AnyAsync(r =>
            r.ListingId == dto.ListingId &&
            r.Status != RequestStatus.Rejected &&
            r.FromDate <= dto.ToDate &&
            r.ToDate >= dto.FromDate);

        if (hasConflict)
            return ServiceResult<int>.Fail("These dates are already booked or requested. Please choose different dates.");

        int days = Math.Max(1, dto.ToDate.DayNumber - dto.FromDate.DayNumber);
        decimal totalCost = days * listing.CostPerDay;

        var request = new RentalRequest
        {
            ListingId = dto.ListingId,
            UserId = dto.UserId,
            FromDate = dto.FromDate,
            ToDate = dto.ToDate,
            FromTime = dto.FromTime,
            ToTime = dto.ToTime,
            TotalCost = totalCost,
            OtpVerified = true,
            Status = RequestStatus.Pending
        };

        await _uow.RentalRequests.AddAsync(request);
        await _uow.SaveChangesAsync();
        _logger.LogInformation("Rental request {Id} created for listing {Listing}", request.Id, dto.ListingId);
        return ServiceResult<int>.Ok(request.Id);
    }

    public Task<List<RentalRequest>> GetMyRequestsAsync(int userId)
        => _uow.RentalRequests.Query()
            .AsNoTracking()
            .Include(r => r.Listing).ThenInclude(l => l!.Owner)
            .Include(r => r.Rating)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

    public Task<List<RentalRequest>> GetRequestsForListingAsync(int listingId, int ownerId)
        => _uow.RentalRequests.Query()
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Listing)
            .Where(r => r.ListingId == listingId && r.Listing!.OwnerId == ownerId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

    public Task<List<RentalRequest>> GetIncomingForOwnerAsync(int ownerId)
        => _uow.RentalRequests.Query()
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Listing)
            .Where(r => r.Listing!.OwnerId == ownerId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

    public Task<List<RentalRequest>> GetAllAsync()
        => _uow.RentalRequests.Query()
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Listing)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

    public async Task<ServiceResult> AcceptAsync(int requestId, int ownerId)
        => await UpdateStatusAsync(requestId, ownerId, RequestStatus.Accepted);

    public async Task<ServiceResult> RejectAsync(int requestId, int ownerId)
        => await UpdateStatusAsync(requestId, ownerId, RequestStatus.Rejected);

    private async Task<ServiceResult> UpdateStatusAsync(int requestId, int ownerId, RequestStatus newStatus)
    {
        var request = await _uow.RentalRequests.Query()
            .Include(r => r.Listing).ThenInclude(l => l!.Owner)
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == requestId);

        if (request is null) return ServiceResult.Fail("Request not found.");
        if (request.Listing!.OwnerId != ownerId)
            return ServiceResult.Fail("You are not allowed to update this request.");
        if (request.Status != RequestStatus.Pending)
            return ServiceResult.Fail($"This request has already been {request.Status.ToString().ToLower()}.");

        request.Status = newStatus;
        _uow.RentalRequests.Update(request);
        await _uow.SaveChangesAsync();

        var renter = request.User!;
        var ownerPhone = request.Listing.Owner!.PhoneNumber;
        if (newStatus == RequestStatus.Accepted)
            await _email.SendRequestAcceptedAsync(renter.EmailAddress, renter.FullName, request.Listing.Title, ownerPhone, request.TotalCost);
        else
            await _email.SendRequestRejectedAsync(renter.EmailAddress, renter.FullName, request.Listing.Title, ownerPhone);

        return ServiceResult.Ok();
    }

    /// <summary>Deletes a request; returns its image-less info. Only owner-of-request or admin.</summary>
    public async Task<ServiceResult> DeleteAsync(int requestId, int? actingUserId = null, bool isAdmin = false)
    {
        var request = await _uow.RentalRequests.GetByIdAsync(requestId);
        if (request is null) return ServiceResult.Fail("Request not found.");
        if (!isAdmin && actingUserId is not null && request.UserId != actingUserId)
            return ServiceResult.Fail("You are not allowed to delete this request.");

        _uow.RentalRequests.Remove(request);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }
}
