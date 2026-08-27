using System.Collections.Concurrent;
using System.Security.Cryptography;
using Equipify.Service.Services.Interfaces;
using Equipify.Service.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Equipify.Service.Services;

/// <summary>
/// In-memory OTP service: random 6-digit codes with expiry, resend cooldown
/// and a maximum number of verification attempts. Codes are stored hashed.
/// (Swap for a distributed cache/Redis + real SMS provider in production.)
/// </summary>
public class OtpService : IOtpService
{
    private sealed record Entry(string Hash, DateTime ExpiresAt, DateTime NextResendAllowedAt);

    private readonly ConcurrentDictionary<string, (string Hash, DateTime ExpiresAt, int Attempts, DateTime LockedUntil, DateTime ResendAt)> _store = new();
    private readonly OtpSettings _settings;
    private readonly ILogger<OtpService> _logger;

    public OtpService(IOptions<OtpSettings> settings, ILogger<OtpService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public Task<string?> IssueOtpAsync(string phoneNumber)
    {
        var key = Normalize(phoneNumber);
        var now = DateTime.UtcNow;

        if (_store.TryGetValue(key, out var existing) && existing.ResendAt > now)
            throw new InvalidOperationException($"Please wait {(int)Math.Ceiling((existing.ResendAt - now).TotalSeconds)}s before requesting another code.");

        var code = !string.IsNullOrWhiteSpace(_settings.FixedCode) && _settings.EchoCode
            ? _settings.FixedCode
            : RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        var expires = now.AddMinutes(_settings.ExpiryMinutes);
        var resendAt = now.AddSeconds(_settings.ResendCooldownSeconds);

        _store[key] = (Hash(code), expires, 0, DateTime.MinValue, resendAt);

        if (!_settings.EchoCode)
        {
            // Production: integrate an SMS provider here and never expose the code.
            return Task.FromResult<string?>(null);
        }

        // Development convenience: log it so testers can read it from console/file.
        _logger.LogInformation("OTP issued for {Phone}: {Code} (expires in {Minutes}m)", phoneNumber, code, _settings.ExpiryMinutes);
        return Task.FromResult<string?>(code);
    }

    public bool Verify(string phoneNumber, string code)
    {
        var key = Normalize(phoneNumber);
        var now = DateTime.UtcNow;

        if (string.IsNullOrWhiteSpace(code) || !_store.TryGetValue(key, out var entry))
            return false;

        if (now > entry.ExpiresAt || now < entry.LockedUntil)
        {
            _store.TryRemove(key, out _);
            return false;
        }

        if (!CryptographicOperations.FixedTimeEquals(Convert.FromHexString(Hash(code)), Convert.FromHexString(entry.Hash)))
        {
            var attempts = entry.Attempts + 1;
            if (attempts >= _settings.MaxAttempts)
                _store.TryRemove(key, out _);
            else
                _store[key] = (entry.Hash, entry.ExpiresAt, attempts, entry.LockedUntil, entry.ResendAt);
            return false;
        }

        _store.TryRemove(key, out _); // single use
        return true;
    }

    private static string Normalize(string phone) => phone.Trim();

    private static string Hash(string code)
        => Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(code))).ToLowerInvariant();
}
