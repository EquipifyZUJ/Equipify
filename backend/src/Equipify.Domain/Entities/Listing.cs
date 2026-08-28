using Equipify.Domain.Enums;

namespace Equipify.Domain.Entities;

/// <summary>An item/equipment offered for rent by an owner.</summary>
public class Listing
{
    public int Id { get; set; }

    public int OwnerId { get; set; }
    public User? Owner { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    /// <summary>Relative path (under wwwroot) or image bytes reference.</summary>
    public string? MainImage { get; set; }

    /// <summary>Raw main image bytes stored in the database.</summary>
    public byte[]? MainImageBytes { get; set; }

    /// <summary>MIME type of the main image.</summary>
    public string? MainImageContentType { get; set; }

    public int CategoryId { get; set; }
    public Category? Category { get; set; }

    public string LocationAddress { get; set; } = string.Empty;

    // ----- Flexible pricing -----
    /// <summary>The primary rental unit: "hour", "day", "week", "month", or "year".</summary>
    public string RentalUnit { get; set; } = "day";

    public decimal? CostPerHour { get; set; }
    public decimal CostPerDay { get; set; }
    public decimal? CostPerWeek { get; set; }
    public decimal? CostPerMonth { get; set; }
    public decimal? CostPerYear { get; set; }

    /// <summary>Minimum rental duration in the listing's RentalUnit (e.g. 2 hours, 1 day, 1 week).</summary>
    public int? MinRentalDays { get; set; }

    /// <summary>Maximum rental duration in the listing's RentalUnit (e.g. 8 hours, 30 days, 12 weeks).</summary>
    public int? MaxRentalDays { get; set; }

    /// <summary>Latitude of the pickup location shown on the map.</summary>
    public double Latitude { get; set; }

    /// <summary>Longitude of the pickup location shown on the map.</summary>
    public double Longitude { get; set; }

    /// <summary>Number of ratings the listing/owner has accumulated.</summary>
    public int TotalRates { get; set; }

    public ListingStatus Status { get; set; } = ListingStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<ListingImage> Images { get; set; } = new List<ListingImage>();
    public ICollection<RentalRequest> RentalRequests { get; set; } = new List<RentalRequest>();
}
