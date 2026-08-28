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
        [FromQuery] int? categoryId)
        => Ok((await _listings.GetForMapAsync(west, south, east, north, categoryId))
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

    /// <summary>Creates a listing from multipart form-data (fields + images).</summary>
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

        var paths = dbImages.Select(i => i.Path).ToList();
        var result = await _listings.CreateAsync(form.ToDto(paths, CurrentUserId));

        if (result.Success)
        {
            // Save image bytes to DB for persistent storage
            var listingId = result.Value;
            foreach (var (path, bytes, ct) in dbImages)
            {
                var img = new ListingImage
                {
                    ListingId = listingId,
                    ImagePath = path,
                    ImageBytes = bytes,
                    ContentType = ct
                };
                _db.ListingImages.Add(img);
            }

            // Set main image bytes on listing
            var listing = await _db.Listings.FindAsync(listingId);
            if (listing is not null && dbImages.Count > 0)
            {
                listing.MainImageBytes = dbImages[0].Bytes;
                listing.MainImageContentType = dbImages[0].ContentType;
            }

            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Details), new { id = listingId }, new { id = listingId });
        }

        return ApiResults.FromResult(result);
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

        var paths = dbImages?.Select(i => i.Path).ToList();
        var result = await _listings.UpdateAsync(form.ToDto(paths ?? new(), CurrentUserId, id));

        if (result.Success && dbImages is not null && dbImages.Count > 0)
        {
            foreach (var (path, bytes, ct) in dbImages)
            {
                _db.ListingImages.Add(new ListingImage
                {
                    ListingId = id,
                    ImagePath = path,
                    ImageBytes = bytes,
                    ContentType = ct
                });
            }

            var listing = await _db.Listings.FindAsync(id);
            if (listing is not null)
            {
                listing.MainImageBytes = dbImages[0].Bytes;
                listing.MainImageContentType = dbImages[0].ContentType;
            }

            await _db.SaveChangesAsync();
        }

        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Activates/deactivates an owned listing.</summary>
    [Authorize(Roles = "User")]
    [HttpPost("{id:int}/status")]
    public async Task<IActionResult> SetStatus(int id, SetListingStatusRequest request)
    {
        if (!Enum.TryParse<ListingStatus>(request.Status, ignoreCase: true, out var status) || status == ListingStatus.Pending)
            return BadRequest(new { error = "Status must be Active or Inactive." });

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

        if (result is ServiceResult<List<string>> { Value: not null } withPaths)
            DeleteFiles(withPaths.Value);
        return NoContent();
    }

    internal void DeleteFiles(IEnumerable<string> webPaths)
    {
        var root = HttpContext.RequestServices.GetRequiredService<IWebHostEnvironment>();
        var wwwroot = root.WebRootPath ?? Path.Combine(root.ContentRootPath, "wwwroot");
        foreach (var path in webPaths)
        {
            var safe = path.Replace('\\', '/').TrimStart('/');
            if (!safe.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase)) continue;
            try { System.IO.File.Delete(Path.Combine(wwwroot, safe)); }
            catch { /* best effort */ }
        }
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
