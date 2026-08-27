namespace Equipify.Domain.Entities;

/// <summary>A grouping of listings (e.g. Electronics, Vehicles).</summary>
public class Category
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameAr { get; set; }

    /// <summary>Relative path (under wwwroot) to the category image.</summary>
    public string? Picture { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Listing> Listings { get; set; } = new List<Listing>();
}
