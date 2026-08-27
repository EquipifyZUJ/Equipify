using Equipify.Service.Services.Interfaces;
using Equipify.Service.Settings;
using Microsoft.Extensions.Options;

namespace Equipify.Service.Services;

public class AdminAuthService : IAdminAuthService
{
    private readonly AdminSettings _settings;

    // Precomputed dummy hash so a wrong username costs the same time as a
    // wrong password (mitigates user-enumeration via response timing).
    private const string DummyHash = "$2a$11$C6UzMDM.H6dfI/f/IKcEeO7ZBpUuUPYtRXbGJEfDpNXPZ4pKJmDlO";

    public AdminAuthService(IOptions<AdminSettings> settings) => _settings = settings.Value;

    public string AdminUsername => _settings.Username;

    public bool ValidateCredentials(string username, string password)
    {
        var userMatch = string.Equals(username?.Trim(), _settings.Username.Trim(), StringComparison.Ordinal);
        // Always run BCrypt once so timing does not reveal which field was wrong.
        var passwordMatch = BCrypt.Net.BCrypt.Verify(password ?? string.Empty, userMatch ? _settings.PasswordHash : DummyHash);
        return userMatch && passwordMatch;
    }
}
