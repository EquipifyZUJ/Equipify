namespace Equipify.Service.Settings;

/// <summary>SMTP email configuration. When <see cref="Enabled"/> is false,
/// emails are written to the log instead of being sent.</summary>
public class EmailSettings
{
    public const string SectionName = "Email";

    public bool Enabled { get; set; } = false;
    public string Host { get; set; } = "smtp.gmail.com";
    public int Port { get; set; } = 587;
    public bool UseSsl { get; set; } = true;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromEmail { get; set; } = "no-reply@equipify.local";
    public string FromName { get; set; } = "Equipify";
}
