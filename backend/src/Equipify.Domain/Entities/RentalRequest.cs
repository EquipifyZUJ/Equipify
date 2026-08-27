using Equipify.Domain.Enums;

namespace Equipify.Domain.Entities;

/// <summary>A renter's request to rent a listing for a date/time range.</summary>
public class RentalRequest
{
    public int Id { get; set; }

    public int ListingId { get; set; }
    public Listing? Listing { get; set; }

    /// <summary>The renter who placed the request.</summary>
    public int UserId { get; set; }
    public User? User { get; set; }

    public DateOnly FromDate { get; set; }
    public DateOnly ToDate { get; set; }
    public TimeOnly FromTime { get; set; }
    public TimeOnly ToTime { get; set; }

    public decimal TotalCost { get; set; }

    /// <summary>Whether the phone OTP was verified when the request was made.</summary>
    public bool OtpVerified { get; set; }

    public RequestStatus Status { get; set; } = RequestStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public UserRating? Rating { get; set; }
}
