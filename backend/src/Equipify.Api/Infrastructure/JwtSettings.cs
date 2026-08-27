namespace Equipify.Api.Infrastructure;

/// <summary>JWT configuration bound from the "Jwt" section.</summary>
public class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Equipify.Api";
    public string Audience { get; set; } = "Equipify.Client";

    /// <summary>Signing key (HMAC-SHA256). Must be kept secret in production.</summary>
    public string SecretKey { get; set; } = string.Empty;

    /// <summary>Access-token lifetime for regular users.</summary>
    public int AccessTokenMinutes { get; set; } = 60;

    /// <summary>Access-token lifetime for the admin (shorter-lived).</summary>
    public int AdminAccessTokenMinutes { get; set; } = 120;

    /// <summary>Refresh-token lifetime.</summary>
    public int RefreshTokenDays { get; set; } = 7;
}
