using Equipify.Domain.Entities;
using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface IUserService
{
    Task<User?> AuthenticateAsync(string phoneNumber, string password);
    Task<ServiceResult> RegisterAsync(RegisterDto dto);
    Task<User?> GetByIdAsync(int id);
    Task<List<User>> GetAllAsync();
    Task<ServiceResult> UpdateProfileAsync(UpdateProfileDto dto);

    /// <summary>Changes the password after verifying the current one.</summary>
    Task<ServiceResult> ChangePasswordAsync(ChangePasswordDto dto);

    /// <summary>Check if email is already registered.</summary>
    Task<bool> EmailExistsAsync(string email);

    /// <summary>Check if phone is already registered.</summary>
    Task<bool> PhoneExistsAsync(string phone);

    /// <summary>Get user by phone number (for password reset).</summary>
    Task<User?> GetByPhoneAsync(string phone);

    /// <summary>Reset password after OTP verification.</summary>
    Task<ServiceResult> ResetPasswordAsync(ResetPasswordDto dto);

    /// <summary>Fuzzy search by name, email, or phone (substring match).</summary>
    Task<List<User>> SearchAsync(string term, int limit = 20);

    // Admin operations
    Task<ServiceResult> AdminUpdateAsync(int id, string firstName, string lastName, string email, string phone);
    Task<ServiceResult> ToggleStatusAsync(int id);
    Task<ServiceResult> DeleteAsync(int id);
}
