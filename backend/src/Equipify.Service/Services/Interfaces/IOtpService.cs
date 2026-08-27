namespace Equipify.Service.Services.Interfaces;

public interface IOtpService
{
    /// <summary>Generates a new OTP for the phone number. Returns the code when
    /// EchoCode is enabled (development); otherwise returns null.</summary>
    Task<string?> IssueOtpAsync(string phoneNumber);

    /// <summary>Verifies the supplied code for the phone number (expiry + attempt limited).</summary>
    bool Verify(string phoneNumber, string code);
}
