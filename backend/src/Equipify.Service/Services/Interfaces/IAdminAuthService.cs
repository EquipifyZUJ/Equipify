namespace Equipify.Service.Services.Interfaces;

/// <summary>Validates the single administrator account defined in appsettings.</summary>
public interface IAdminAuthService
{
    bool ValidateCredentials(string username, string password);
    string AdminUsername { get; }
}
