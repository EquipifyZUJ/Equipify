namespace Equipify.Service.Settings;

/// <summary>Administrator credentials (from appsettings/secrets). Only the
/// BCrypt hash of the password is stored — never the plaintext.</summary>
public class AdminSettings
{
    public const string SectionName = "Admin";
    public string Username { get; set; } = "admin";

    /// <summary>BCrypt hash. Default corresponds to "Admin@12345" (change in production).</summary>
    public string PasswordHash { get; set; } = "$2a$11$ORsJkKedISKcQ3oZ0MtX0eH8JK67WxDuA2u.AMA4ibQpe7rZBHiu2";

    /// <summary>Convenience for seeding/docs: the default plaintext.</summary>
    public const string DefaultPlaintext = "Admin@12345";
}
