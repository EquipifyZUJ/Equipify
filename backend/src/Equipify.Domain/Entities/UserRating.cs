namespace Equipify.Domain.Entities;

/// <summary>A rating (1-5) left by a renter for a listing's owner after a rental.</summary>
public class UserRating
{
    public int Id { get; set; }

    /// <summary>User who left the rating.</summary>
    public int RenterId { get; set; }
    public User? Renter { get; set; }

    /// <summary>Owner who received the rating.</summary>
    public int OwnerId { get; set; }
    public User? Owner { get; set; }

    public int ListingId { get; set; }
    public Listing? Listing { get; set; }

    public int RentalRequestId { get; set; }
    public RentalRequest? RentalRequest { get; set; }

    /// <summary>Score between 1 and 5.</summary>
    public double Rating { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
