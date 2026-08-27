namespace Equipify.Service.Settings;

/// <summary>OTP configuration. A random code is generated per request; since no
/// SMS provider is wired, <see cref="EchoCode"/> controls whether the code is
/// returned to the caller / logged (development convenience only).</summary>
public class OtpSettings
{
    public const string SectionName = "Otp";

    /// <summary>How long an issued OTP stays valid.</summary>
    public int ExpiryMinutes { get; set; } = 5;

    /// <summary>Maximum verification attempts before the code is invalidated.</summary>
    public int MaxAttempts { get; set; } = 3;

    /// <summary>Minimum seconds between two issues for the same phone number.</summary>
    public int ResendCooldownSeconds { get; set; } = 60;

    /// <summary>Development helper: return/log the generated code instead of sending a real SMS.</summary>
    public bool EchoCode { get; set; } = true;

    /// <summary>When EchoCode is on and this is non-empty, this fixed code is used instead of a random one (dev/testing convenience).</summary>
    public string? FixedCode { get; set; }
}
