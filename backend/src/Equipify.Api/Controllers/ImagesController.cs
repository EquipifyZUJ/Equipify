using Equipify.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/images")]
public class ImagesController : ControllerBase
{
    private readonly EquipifyDbContext _db;
    public ImagesController(EquipifyDbContext db) => _db = db;

    /// <summary>Serves an image by listing ID + index (0=main, 1..N=gallery).</summary>
    [HttpGet("{listingId:int}/{index:int}")]
    [ResponseCache(Duration = 86400)]
    public async Task<IActionResult> GetImage(int listingId, int index)
    {
        byte[]? bytes = null;
        string? contentType = null;

        if (index == 0)
        {
            var listing = await _db.Listings.AsNoTracking().FirstOrDefaultAsync(l => l.Id == listingId);
            if (listing is null) return NotFound();
            bytes = listing.MainImageBytes;
            contentType = listing.MainImageContentType;
        }
        else
        {
            var img = await _db.ListingImages
                .AsNoTracking()
                .Where(i => i.ListingId == listingId)
                .OrderBy(i => i.Id)
                .Skip(index - 1)
                .FirstOrDefaultAsync();
            bytes = img?.ImageBytes;
            contentType = img?.ContentType;
        }

        if (bytes is null || bytes.Length == 0) return NotFound();
        contentType ??= "image/jpeg";
        return File(bytes, contentType);
    }

    /// <summary>Serves an uploaded image by its filename from the DB (fallback for /uploads/ paths).</summary>
    [HttpGet("file/{fileName}")]
    [ResponseCache(Duration = 86400)]
    public async Task<IActionResult> GetByFileName(string fileName)
    {
        var img = await _db.ListingImages
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.ImagePath.Contains(fileName));

        if (img?.ImageBytes is null || img.ImageBytes.Length == 0)
        {
            // Try listing main image
            var listing = await _db.Listings
                .AsNoTracking()
                .FirstOrDefaultAsync(l => l.MainImage != null && l.MainImage.Contains(fileName));

            if (listing?.MainImageBytes is null || listing.MainImageBytes.Length == 0)
                return NotFound();

            return File(listing.MainImageBytes, listing.MainImageContentType ?? "image/jpeg");
        }

        return File(img.ImageBytes, img.ContentType ?? "image/jpeg");
    }
}
