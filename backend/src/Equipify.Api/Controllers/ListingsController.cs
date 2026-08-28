using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Api.Services;
using Equipify.Data;
using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/listings")]
public class ListingsController : ControllerBase
{
    private readonly IListingService _listings;
    private readonly IFileStorageService _files;
    private readonly EquipifyDbContext _db;

    public ListingsController(IListingService listings, IFileStorageService files, EquipifyDbContext db)
    {
        _listings = listings;
        _files = files;
        _db = db;
    }

    /// <summary>Browse active listings (filters + pagination).</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<ListingSummaryDto>>> Browse(
        [FromQuery] string? search, [FromQuery] int? categoryId,
        [FromQuery] decimal? minPrice, [FromQuery] decimal? maxPrice,
        [FromQuery] string? rentalUnit,
        [FromQuery] int? minDuration, [FromQuery] int? maxDuration,
        [FromQuery] double? west, [FromQuery] double? south,
        [FromQuery] double? east, [FromQuery] double? north,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 12)
    {
        var result = await _listings.BrowseAsync(new ListingFilterDto
        {
            Search = search,
            CategoryId = categoryId,
            MinPrice = minPrice,
            MaxPrice = maxPrice,
            RentalUnit = rentalUnit,
            MinDuration = minDuration,
            MaxDuration = maxDuration,
            West = west, South = south, East = east, North = north,
            Page = page,
            PageSize = pageSize
        });

        return Ok(new PagedResponse<ListingSummaryDto>(
            result.Items.Select(ListingSummaryDto.From).ToList(),
            result.Page, result.PageSize, result.TotalCount, result.TotalPages));
    }

    /// <summary>Lightweight markers for the map within a viewport (max 300).</summary>
    [HttpGet("map")]
    [AllowAnonymous]
    public async Task<ActionResult<List<MapMarkerDto>>> Map(
        [FromQuery] double west, [FromQuery] double south,
        [FromQuery] double east, [FromQuery] double north,
        [FromQuery] int? categoryId, [FromQuery] string? search)
        => Ok((await _listings.GetForMapAsync(west, south, east, north, categoryId, search))
            .Select(MapMarkerDto.From).ToList());

    /// <summary>Listing details.</summary>
    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<ListingDto>> Details(int id)
    {
        var privileged = User.Identity?.IsAuthenticated == true;
        var listing = await _listings.GetDetailsAsync(id, includeInactive: privileged);
        if (listing is null) return NotFound();

        return Ok(ListingDto.From(listing));
    }

    /// <summary>Listings owned by the authenticated user.</summary>
    [Authorize(Roles = "User")]
    [HttpGet("mine")]
    public async Task<ActionResult<List<ListingSummaryDto>>> Mine()
        => Ok((await _listings.GetByOwnerAsync(CurrentUserId))
            .Select(ListingSummaryDto.From).ToList());

    /// <summary>Creates a listing from multipart form-data (fields + images).
    /// Images are stored in a single transaction with bytes for Render-safe persistence.</summary>
    [Authorize(Roles = "User")]
    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(35_000_000)]
    public async Task<IActionResult> Create([FromForm] ListingForm form)
    {
        if (form.Images is null || form.Images.Count == 0)
            return BadRequest(new { error = "Please upload at least one image." });

        List<(string Path, byte[] Bytes, string ContentType)> dbImages;
        try { dbImages = await _files.SaveImagesToDbAsync(form.Images, "listings"); }
        catch (InvalidOperationException ex) { return BadRequest(new { error = ex.Message }); }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = $"Image processing failed: {ex.Message}" });
        }

        if (dbImages.Count == 0)
            return BadRequest(new { error = "No valid image was uploaded (jpg/png/gif/webp)." });

        // Build the complete entity graph with bytes — one SaveChanges, zero ambiguity.
        var listing = new Listing
        {
            OwnerId = CurrentUserId,
            Title = form.Title.Trim(),
            Description = form.Description?.Trim() ?? string.Empty,
            CategoryId = form.CategoryId,
            LocationAddress = form.LocationAddress?.Trim() ?? string.Empty,
            RentalUnit = form.RentalUnit ?? "day",
            CostPerHour = form.CostPerHour,
            CostPerDay = form.CostPerDay,
            CostPerWeek = form.CostPerWeek,
            CostPerMonth = form.CostPerMonth,
            CostPerYear = form.CostPerYear,
            MinRentalDays = form.MinRentalDays,
            MaxRentalDays = form.MaxRentalDays,
            Latitude = form.Latitude,
            Longitude = form.Longitude,
            MainImage = dbImages[0].Path,
            MainImageBytes = dbImages[0].Bytes,
            MainImageContentType = dbImages[0].ContentType,
            Status = ListingStatus.Pending,
            Images = dbImages.Select(img => new ListingImage
            {
                ImagePath = img.Path,
                ImageBytes = img.Bytes,
                ContentType = img.ContentType
            }).ToList()
        };

        _db.Listings.Add(listing);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(Details), new { id = listing.Id }, new { id = listing.Id });
    }

    /// <summary>Updates an owned listing; new content returns it to Pending for re-approval.</summary>
    [Authorize(Roles = "User")]
    [HttpPut("{id:int}")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(35_000_000)]
    public async Task<IActionResult> Update(int id, [FromForm] ListingForm form)
    {
        if (form.Images is not null && form.Images.Count > 6)
            return BadRequest(new { error = "A maximum of 6 images is allowed." });

        var existing = await _db.Listings.FindAsync(id);
        if (existing is null) return NotFound();
        if (existing.OwnerId != CurrentUserId) return Forbid();

        List<(string Path, byte[] Bytes, string ContentType)>? dbImages = null;
        if (form.Images is not null && form.Images.Count > 0)
        {
            try { dbImages = await _files.SaveImagesToDbAsync(form.Images, "listings"); }
            catch (InvalidOperationException ex) { return BadRequest(new { error = ex.Message }); }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Image processing failed: {ex.Message}" });
            }
        }

        // Update listing fields
        existing.Title = form.Title.Trim();
        existing.Description = form.Description?.Trim() ?? string.Empty;
        existing.CategoryId = form.CategoryId;
        existing.LocationAddress = form.LocationAddress?.Trim() ?? string.Empty;
        existing.RentalUnit = form.RentalUnit ?? "day";
        existing.CostPerHour = form.CostPerHour;
        existing.CostPerDay = form.CostPerDay;
        existing.CostPerWeek = form.CostPerWeek;
        existing.CostPerMonth = form.CostPerMonth;
        existing.CostPerYear = form.CostPerYear;
        existing.MinRentalDays = form.MinRentalDays;
        existing.MaxRentalDays = form.MaxRentalDays;
        existing.Latitude = form.Latitude;
        existing.Longitude = form.Longitude;

        // Only reset to Pending if user actually changed content
        if (existing.Status == ListingStatus.Active)
            existing.Status = ListingStatus.Pending;

        // Replace images atomically if new ones were uploaded
        if (dbImages is not null && dbImages.Count > 0)
        {
            var oldImages = await _db.ListingImages.Where(i => i.ListingId == id).ToListAsync();
            _db.ListingImages.RemoveRange(oldImages);

            existing.MainImage = dbImages[0].Path;
            existing.MainImageBytes = dbImages[0].Bytes;
            existing.MainImageContentType = dbImages[0].ContentType;

            foreach (var img in dbImages)
            {
                _db.ListingImages.Add(new ListingImage
                {
                    ListingId = id,
                    ImagePath = img.Path,
                    ImageBytes = img.Bytes,
                    ContentType = img.ContentType
                });
            }
        }

        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Activates/deactivates an owned listing (Active ↔ Inactive).</summary>
    [Authorize(Roles = "User")]
    [HttpPost("{id:int}/status")]
    public async Task<IActionResult> SetStatus(int id, SetListingStatusRequest request)
    {
        if (!Enum.TryParse<ListingStatus>(request.Status, ignoreCase: true, out var status))
            return BadRequest(new { error = "Invalid status." });

        if (status != ListingStatus.Active && status != ListingStatus.Inactive)
            return BadRequest(new { error = "Only Active or Inactive is allowed." });

        var result = await _listings.SetStatusAsync(id, status, CurrentUserId);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Deletes an owned listing and its images.</summary>
    [Authorize(Roles = "User")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await _listings.DeleteAsync(id, CurrentUserId);
        if (!result.Success) return ApiResults.FromResult(result);
        return NoContent();
    }

    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

/// <summary>Multipart binding model for create/update listing.</summary>
public class ListingForm
{
    [FromForm(Name = "title")] public string Title { get; set; } = string.Empty;
    [FromForm(Name = "description")] public string? Description { get; set; }
    [FromForm(Name = "categoryId")] public int CategoryId { get; set; }
    [FromForm(Name = "locationAddress")] public string LocationAddress { get; set; } = string.Empty;
    [FromForm(Name = "rentalUnit")] public string? RentalUnit { get; set; }
    [FromForm(Name = "costPerHour")] public decimal? CostPerHour { get; set; }
    [FromForm(Name = "costPerDay")] public decimal CostPerDay { get; set; }
    [FromForm(Name = "costPerWeek")] public decimal? CostPerWeek { get; set; }
    [FromForm(Name = "costPerMonth")] public decimal? CostPerMonth { get; set; }
    [FromForm(Name = "costPerYear")] public decimal? CostPerYear { get; set; }
    [FromForm(Name = "minRentalDays")] public int? MinRentalDays { get; set; }
    [FromForm(Name = "maxRentalDays")] public int? MaxRentalDays { get; set; }
    [FromForm(Name = "latitude")] public double Latitude { get; set; }
    [FromForm(Name = "longitude")] public double Longitude { get; set; }
    [FromForm(Name = "images")] public List<IFormFile>? Images { get; set; }

    public ListingInputDto ToDto(List<string> imagePaths, int ownerId, int id = 0) => new()
    {
        Id = id,
        OwnerId = ownerId,
        Title = Title,
        Description = Description ?? string.Empty,
        CategoryId = CategoryId,
        LocationAddress = LocationAddress,
        RentalUnit = RentalUnit ?? "day",
        CostPerHour = CostPerHour,
        CostPerDay = CostPerDay,
        CostPerWeek = CostPerWeek,
        CostPerMonth = CostPerMonth,
        CostPerYear = CostPerYear,
        MinRentalDays = MinRentalDays,
        MaxRentalDays = MaxRentalDays,
        Latitude = Latitude,
        Longitude = Longitude,
        ImagePaths = imagePaths
    };
}
