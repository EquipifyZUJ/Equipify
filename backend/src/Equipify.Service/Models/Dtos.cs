using Equipify.Domain.Entities;

namespace Equipify.Service.Models;

/// <summary>New user registration input.</summary>
public class RegisterDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string EmailAddress { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>Profile update input.</summary>
public class UpdateProfileDto
{
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string EmailAddress { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
}

/// <summary>Password change input (requires the current password).</summary>
public class ChangePasswordDto
{
    public int UserId { get; set; }
    public string CurrentPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>Reset password via OTP.</summary>
public class ResetPasswordDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>Create/edit listing input. Image paths are saved by the API layer.</summary>
public class ListingInputDto
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int CategoryId { get; set; }
    public string LocationAddress { get; set; } = string.Empty;

    /// <summary>The primary rental unit: "hour", "day", "week", "month", or "year".</summary>
    public string RentalUnit { get; set; } = "day";

    // Flexible pricing
    public decimal? CostPerHour { get; set; }
    public decimal CostPerDay { get; set; }
    public decimal? CostPerWeek { get; set; }
    public decimal? CostPerMonth { get; set; }
    public decimal? CostPerYear { get; set; }
    public int? MinRentalDays { get; set; }
    public int? MaxRentalDays { get; set; }

    /// <summary>Pickup location shown on the map.</summary>
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    /// <summary>Relative paths of newly uploaded images (first becomes the main image).</summary>
    public List<string> ImagePaths { get; set; } = new();
}

/// <summary>Public listing browse filters.</summary>
public class ListingFilterDto
{
    public string? Search { get; set; }
    public int? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }

    /// <summary>Filter by rental unit: "hour", "day", "week", "month", "year". Only listings with a price for this unit are returned.</summary>
    public string? RentalUnit { get; set; }

    /// <summary>Minimum rental duration in days.</summary>
    public int? MinDuration { get; set; }

    /// <summary>Maximum rental duration in days.</summary>
    public int? MaxDuration { get; set; }

    /// <summary>Map viewport bounds: "west,south,east,north" (WGS84 degrees).</summary>
    public double? West { get; set; }
    public double? South { get; set; }
    public double? East { get; set; }
    public double? North { get; set; }

    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 12;

    public int Skip => Math.Max(0, (Page - 1)) * PageSize;

    public bool HasBbox => West is not null && South is not null && East is not null && North is not null;
}

/// <summary>Paged result wrapper.</summary>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}

/// <summary>Create rental request input.</summary>
public class RentalRequestDto
{
    public int ListingId { get; set; }
    public int UserId { get; set; }
    public DateOnly FromDate { get; set; }
    public DateOnly ToDate { get; set; }
    public TimeOnly FromTime { get; set; }
    public TimeOnly ToTime { get; set; }
    public bool OtpVerified { get; set; }
}

/// <summary>Aggregate counts for the admin dashboard.</summary>
public class DashboardStats
{
    public int Users { get; set; }
    public int Listings { get; set; }
    public int ActiveListings { get; set; }
    public int PendingListings { get; set; }
    public int Categories { get; set; }
    public int Requests { get; set; }
    public int PendingRequests { get; set; }
}
