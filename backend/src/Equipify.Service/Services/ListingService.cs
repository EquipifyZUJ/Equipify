using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Equipify.Service.Services;

public class ListingService : IListingService
{
    private readonly IUnitOfWork _uow;
    private readonly ILogger<ListingService> _logger;

    public ListingService(IUnitOfWork uow, ILogger<ListingService> logger)
    {
        _uow = uow;
        _logger = logger;
    }

    public async Task<PagedResult<Listing>> BrowseAsync(ListingFilterDto filter)
    {
        var query = _uow.Listings.Query()
            .Include(l => l.Category)
            .Include(l => l.Owner)
            .AsNoTracking()
            .Where(l => l.Status == ListingStatus.Active);

        if (filter.CategoryId is > 0)
            query = query.Where(l => l.CategoryId == filter.CategoryId);

        if (filter.MinPrice is > 0)
            query = query.Where(l => l.CostPerDay >= filter.MinPrice);

        if (filter.MaxPrice is > 0)
            query = query.Where(l => l.CostPerDay <= filter.MaxPrice);

        if (filter.HasBbox)
        {
            var (west, south, east, north) = NormalizeBbox(filter.West!.Value, filter.South!.Value, filter.East!.Value, filter.North!.Value);
            query = query.Where(l =>
                l.Longitude >= west && l.Longitude <= east &&
                l.Latitude >= south && l.Latitude <= north);
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var term = filter.Search.Trim();
            query = query.Where(l =>
                l.Title.Contains(term) ||
                l.Description.Contains(term) ||
                l.LocationAddress.Contains(term) ||
                l.Owner!.FirstName.Contains(term) ||
                l.Owner.LastName.Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(filter.RentalUnit))
        {
            query = filter.RentalUnit.ToLower() switch
            {
                "hour" => query.Where(l => l.CostPerHour != null),
                "day" => query.Where(l => l.CostPerDay > 0),
                "week" => query.Where(l => l.CostPerWeek != null),
                "month" => query.Where(l => l.CostPerMonth != null),
                "year" => query.Where(l => l.CostPerYear != null),
                _ => query,
            };

            // Duration filter: only compare against listings with the same rental unit
            var unitLower = filter.RentalUnit.ToLower();
            if (filter.MinDuration is > 0)
                query = query.Where(l => l.RentalUnit == unitLower && (l.MaxRentalDays == null || l.MaxRentalDays >= filter.MinDuration));

            if (filter.MaxDuration is > 0)
                query = query.Where(l => l.RentalUnit == unitLower && (l.MinRentalDays == null || l.MinRentalDays <= filter.MaxDuration));
        }

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip(Math.Max(0, filter.Skip))
            .Take(Math.Clamp(filter.PageSize, 1, 50))
            .ToListAsync();

        return new PagedResult<Listing>
        {
            Items = items,
            Page = Math.Max(1, filter.Page),
            PageSize = Math.Clamp(filter.PageSize, 1, 50),
            TotalCount = totalCount
        };
    }

    public Task<List<Listing>> GetForMapAsync(double west, double south, double east, double north, int? categoryId = null)
    {
        var (w, s, e, n) = NormalizeBbox(west, south, east, north);
        var query = _uow.Listings.Query()
            .AsNoTracking()
            .Where(l => l.Status == ListingStatus.Active &&
                        l.Longitude >= w && l.Longitude <= e &&
                        l.Latitude >= s && l.Latitude <= n);

        if (categoryId is > 0)
            query = query.Where(l => l.CategoryId == categoryId);

        return query
            .Select(l => new Listing
            {
                Id = l.Id,
                Title = l.Title,
                MainImage = l.MainImage,
                CostPerDay = l.CostPerDay,
                LocationAddress = l.LocationAddress,
                Latitude = l.Latitude,
                Longitude = l.Longitude
            })
            .Take(300)
            .ToListAsync();
    }

    public Task<Listing?> GetDetailsAsync(int id, bool includeInactive = false)
    {
        var query = _uow.Listings.Query()
            .Include(l => l.Category)
            .Include(l => l.Owner)
            .Include(l => l.Images)
            .AsNoTracking();

        return includeInactive
            ? query.FirstOrDefaultAsync(l => l.Id == id)
            : query.FirstOrDefaultAsync(l => l.Id == id && l.Status == ListingStatus.Active);
    }

    public Task<List<Listing>> GetByOwnerAsync(int ownerId)
        => _uow.Listings.Query()
            .AsNoTracking()
            .Include(l => l.Category)
            .Where(l => l.OwnerId == ownerId)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

    public Task<List<Listing>> GetAllAsync()
        => _uow.Listings.Query()
            .AsNoTracking()
            .Include(l => l.Category)
            .Include(l => l.Owner)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

    public async Task<ServiceResult<int>> CreateAsync(ListingInputDto dto)
    {
        var validation = Validate(dto);
        if (!validation.Success) return ServiceResult<int>.Fail(validation.Error!);

        var listing = new Listing
        {
            OwnerId = dto.OwnerId,
            Title = dto.Title.Trim(),
            Description = dto.Description?.Trim() ?? string.Empty,
            CategoryId = dto.CategoryId,
            LocationAddress = dto.LocationAddress?.Trim() ?? string.Empty,
            RentalUnit = dto.RentalUnit ?? "day",
            CostPerHour = dto.CostPerHour,
            CostPerDay = dto.CostPerDay,
            CostPerWeek = dto.CostPerWeek,
            CostPerMonth = dto.CostPerMonth,
            CostPerYear = dto.CostPerYear,
            MinRentalDays = dto.MinRentalDays,
            MaxRentalDays = dto.MaxRentalDays,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            MainImage = dto.ImagePaths.Count > 0 ? dto.ImagePaths.First() : null,
            Status = ListingStatus.Pending, // requires admin approval
            Images = dto.ImagePaths.Select(p => new ListingImage { ImagePath = p }).ToList()
        };

        await _uow.Listings.AddAsync(listing);
        await _uow.SaveChangesAsync();
        _logger.LogInformation("Listing {Id} created by user {Owner}", listing.Id, dto.OwnerId);
        return ServiceResult<int>.Ok(listing.Id);
    }

    public async Task<ServiceResult> UpdateAsync(ListingInputDto dto, bool isAdmin = false)
    {
        var listing = await _uow.Listings.Query()
            .Include(l => l.Images)
            .FirstOrDefaultAsync(l => l.Id == dto.Id);
        if (listing is null) return ServiceResult.Fail("Listing not found.");
        if (!isAdmin && listing.OwnerId != dto.OwnerId)
            return ServiceResult.Fail("You are not allowed to edit this listing.");

        var validation = Validate(dto);
        if (!validation.Success) return validation;

        listing.Title = dto.Title.Trim();
        listing.Description = dto.Description?.Trim() ?? string.Empty;
        listing.CategoryId = dto.CategoryId;
        listing.LocationAddress = dto.LocationAddress?.Trim() ?? string.Empty;
        listing.RentalUnit = dto.RentalUnit ?? "day";
        listing.CostPerHour = dto.CostPerHour;
        listing.CostPerDay = dto.CostPerDay;
        listing.CostPerWeek = dto.CostPerWeek;
        listing.CostPerMonth = dto.CostPerMonth;
        listing.CostPerYear = dto.CostPerYear;
        listing.MinRentalDays = dto.MinRentalDays;
        listing.MaxRentalDays = dto.MaxRentalDays;
        listing.Latitude = dto.Latitude;
        listing.Longitude = dto.Longitude;

        if (dto.ImagePaths.Count > 0)
        {
            foreach (var p in dto.ImagePaths)
                listing.Images.Add(new ListingImage { ImagePath = p });
            listing.MainImage = dto.ImagePaths.First();
        }
        else if (!isAdmin && listing.Images.Count > 0 && listing.MainImage is null)
        {
            listing.MainImage = listing.Images.First().ImagePath;
        }

        // Content changed after approval → require admin approval again.
        if (!isAdmin && listing.Status == ListingStatus.Active)
            listing.Status = ListingStatus.Pending;

        _uow.Listings.Update(listing);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> SetStatusAsync(int id, ListingStatus status, int? ownerId = null)
    {
        var listing = await _uow.Listings.GetByIdAsync(id);
        if (listing is null) return ServiceResult.Fail("Listing not found.");
        if (ownerId is not null && listing.OwnerId != ownerId)
            return ServiceResult.Fail("You are not allowed to change this listing.");

        listing.Status = status;
        _uow.Listings.Update(listing);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> DeleteAsync(int id, int? ownerId = null)
    {
        var listing = await _uow.Listings.Query()
            .Include(l => l.Images)
            .FirstOrDefaultAsync(l => l.Id == id);
        if (listing is null) return ServiceResult.Fail("Listing not found.");
        if (ownerId is not null && listing.OwnerId != ownerId)
            return ServiceResult.Fail("You are not allowed to delete this listing.");

        _uow.Listings.Remove(listing);
        await _uow.SaveChangesAsync();
        return ServiceResult<List<string>>.Ok(listing.Images.Select(i => i.ImagePath).ToList());
    }

    private static ServiceResult Validate(ListingInputDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            return ServiceResult.Fail("Title is required.");
        if (dto.Title.Trim().Length > 200)
            return ServiceResult.Fail("Title cannot exceed 200 characters.");
        if (dto.CategoryId <= 0)
            return ServiceResult.Fail("Please choose a category.");
        if (dto.CostPerDay <= 0)
            return ServiceResult.Fail("Cost per day must be greater than zero.");
        if (dto.CostPerDay > 100_000)
            return ServiceResult.Fail("Cost per day seems unrealistic.");
        if (dto.Latitude is < -90 or > 90)
            return ServiceResult.Fail("Latitude must be between -90 and 90.");
        if (dto.Longitude is < -180 or > 180)
            return ServiceResult.Fail("Longitude must be between -180 and 180.");
        if (dto.MinRentalDays is not null && dto.MaxRentalDays is not null && dto.MinRentalDays > dto.MaxRentalDays)
            return ServiceResult.Fail("Minimum rental days cannot exceed maximum rental days.");
        return ServiceResult.Ok();
    }

    private static (double West, double South, double East, double North) NormalizeBbox(double west, double south, double east, double north)
        => (Math.Min(west, east), Math.Min(south, north), Math.Max(west, east), Math.Max(south, north));
}
