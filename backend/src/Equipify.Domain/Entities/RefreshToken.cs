namespace Equipify.Domain.Entities;

/// <summary>A refresh token allowing a client to obtain new JWT access tokens.</summary>
public class RefreshToken
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User? User { get; set; }

    /// <summary>SHA-256 hash of the token (the raw value is only known to the client).</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTime.UtcNow;
}
