using Equipify.Domain.Enums;

namespace Equipify.Domain.Entities;

/// <summary>A marketplace user who can own listings and rent from others.</summary>
public class User
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;

    /// <summary>Computed full name for display.</summary>
    public string FullName => $"{FirstName} {LastName}".Trim();

    public string EmailAddress { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>BCrypt password hash (never store plaintext).</summary>
    public string PasswordHash { get; set; } = string.Empty;

    public UserStatus Status { get; set; } = UserStatus.Active;

    /// <summary>Average rating this user has received as an owner (1-5), or null if unrated.</summary>
    public double? Rating { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Listing> Listings { get; set; } = new List<Listing>();
    public ICollection<RentalRequest> RentalRequests { get; set; } = new List<RentalRequest>();
    public ICollection<UserRating> RatingsReceived { get; set; } = new List<UserRating>();
    public ICollection<UserRating> RatingsGiven { get; set; } = new List<UserRating>();
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}
