namespace Equipify.Domain.Entities;

/// <summary>An additional gallery image belonging to a listing.</summary>
public class ListingImage
{
    public int Id { get; set; }

    public int ListingId { get; set; }
    public Listing? Listing { get; set; }

    /// <summary>Relative path (under wwwroot) or a data URI for legacy images.</summary>
    public string ImagePath { get; set; } = string.Empty;

    /// <summary>Raw image bytes stored in the database (for persistent storage on ephemeral hosts).</summary>
    public byte[]? ImageBytes { get; set; }

    /// <summary>MIME type of the stored image (e.g. "image/jpeg").</summary>
    public string? ContentType { get; set; }
}
