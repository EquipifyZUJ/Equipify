namespace Equipify.Domain.Entities;

/// <summary>An additional gallery image belonging to a listing.</summary>
public class ListingImage
{
    public int Id { get; set; }

    public int ListingId { get; set; }
    public Listing? Listing { get; set; }

    /// <summary>Relative path (under wwwroot) to the image file.</summary>
    public string ImagePath { get; set; } = string.Empty;
}
