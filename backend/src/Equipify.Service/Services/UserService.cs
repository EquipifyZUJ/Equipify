using System.Text.RegularExpressions;
using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Equipify.Service.Services;

public partial class UserService : IUserService
{
    // Precomputed hash of an unguessable password so authentication always
    // runs BCrypt once, even for unknown phones (prevents timing enumeration).
    private const string DummyHash = "$2a$11$C6UzMDM.H6dfI/f/IKcEeO7ZBpUuUPYtRXbGJEfDpNXPZ4pKJmDlO";

    private readonly IUnitOfWork _uow;
    private readonly ILogger<UserService> _logger;

    public UserService(IUnitOfWork uow, ILogger<UserService> logger)
    {
        _uow = uow;
        _logger = logger;
    }

    [GeneratedRegex(@"^(077|078|079)\d{7}$")]
    private static partial Regex PhoneRegex();

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$")]
    private static partial Regex EmailRegex();

    public async Task<User?> AuthenticateAsync(string phoneNumber, string password)
    {
        var user = await _uow.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);
        var hash = user is not null && user.Status == UserStatus.Active ? user.PasswordHash : DummyHash;

        if (!BCrypt.Net.BCrypt.Verify(password ?? string.Empty, hash))
            return null;

        return user;
    }

    public async Task<ServiceResult> RegisterAsync(RegisterDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FirstName))
            return ServiceResult.Fail("First name is required.");
        if (string.IsNullOrWhiteSpace(dto.LastName))
            return ServiceResult.Fail("Last name is required.");
        if (!PhoneRegex().IsMatch(dto.PhoneNumber))
            return ServiceResult.Fail("Phone number must be 10 digits starting with 077, 078, or 079.");
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 8)
            return ServiceResult.Fail("Password must be at least 8 characters long.");
        if (!EmailRegex().IsMatch(dto.EmailAddress))
            return ServiceResult.Fail("Invalid email format.");

        if (await _uow.Users.AnyAsync(u => u.PhoneNumber == dto.PhoneNumber))
            return ServiceResult.Fail("This phone number is already used.");
        if (await _uow.Users.AnyAsync(u => u.EmailAddress == dto.EmailAddress))
            return ServiceResult.Fail("This email address already exists.");

        var user = new User
        {
            FirstName = dto.FirstName.Trim(),
            LastName = dto.LastName.Trim(),
            EmailAddress = dto.EmailAddress.Trim(),
            PhoneNumber = dto.PhoneNumber.Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Status = UserStatus.Active
        };
        await _uow.Users.AddAsync(user);
        await _uow.SaveChangesAsync();
        _logger.LogInformation("New user registered: {Phone}", user.PhoneNumber);
        return ServiceResult.Ok();
    }

    /// <summary>Check if email is already registered (for real-time validation).</summary>
    public Task<bool> EmailExistsAsync(string email) =>
        _uow.Users.AnyAsync(u => u.EmailAddress == email.Trim());

    /// <summary>Check if phone is already registered (for real-time validation).</summary>
    public Task<bool> PhoneExistsAsync(string phone) =>
        _uow.Users.AnyAsync(u => u.PhoneNumber == phone.Trim());

    /// <summary>Get user by phone number (for password reset).</summary>
    public Task<User?> GetByPhoneAsync(string phone) =>
        _uow.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone.Trim());

    /// <summary>Reset password (called after OTP verification).</summary>
    public async Task<ServiceResult> ResetPasswordAsync(ResetPasswordDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < 8)
            return ServiceResult.Fail("New password must be at least 8 characters long.");

        var user = await _uow.Users.FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber.Trim());
        if (user is null) return ServiceResult.Fail("User not found.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        _uow.Users.Update(user);

        // Revoke all refresh tokens after a password reset.
        var activeTokens = await _uow.RefreshTokens.Query()
            .Where(t => t.UserId == user.Id && t.RevokedAt == null)
            .ToListAsync();
        foreach (var token in activeTokens)
            token.RevokedAt = DateTime.UtcNow;

        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public Task<User?> GetByIdAsync(int id) => _uow.Users.GetByIdAsync(id);

    public Task<List<User>> GetAllAsync() => _uow.Users.GetAllAsync();

    public Task<List<User>> SearchAsync(string term, int limit = 20)
    {
        var t = term.Trim().ToLower();
        return _uow.Users.Query()
            .AsNoTracking()
            .Where(u =>
                u.FirstName.ToLower().Contains(t) ||
                u.LastName.ToLower().Contains(t) ||
                u.EmailAddress.ToLower().Contains(t) ||
                u.PhoneNumber.Contains(t))
            .OrderBy(u => u.FirstName)
            .Take(Math.Clamp(limit, 1, 50))
            .ToListAsync();
    }

    public async Task<ServiceResult> UpdateProfileAsync(UpdateProfileDto dto)
    {
        var user = await _uow.Users.GetByIdAsync(dto.UserId);
        if (user is null) return ServiceResult.Fail("User not found.");

        var validation = await ValidateContactAsync(dto.PhoneNumber, dto.EmailAddress, dto.UserId);
        if (!validation.Success) return validation;

        if (string.IsNullOrWhiteSpace(dto.FirstName))
            return ServiceResult.Fail("First name is required.");
        if (string.IsNullOrWhiteSpace(dto.LastName))
            return ServiceResult.Fail("Last name is required.");

        user.FirstName = dto.FirstName.Trim();
        user.LastName = dto.LastName.Trim();
        user.EmailAddress = dto.EmailAddress.Trim();
        user.PhoneNumber = dto.PhoneNumber.Trim();

        _uow.Users.Update(user);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> ChangePasswordAsync(ChangePasswordDto dto)
    {
        var user = await _uow.Users.GetByIdAsync(dto.UserId);
        if (user is null) return ServiceResult.Fail("User not found.");

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword ?? string.Empty, user.PasswordHash))
            return ServiceResult.Fail("Current password is incorrect.");
        if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < 8)
            return ServiceResult.Fail("New password must be at least 8 characters long.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        _uow.Users.Update(user);

        // Revoke all refresh tokens after a password change.
        var activeTokens = await _uow.RefreshTokens.Query()
            .Where(t => t.UserId == dto.UserId && t.RevokedAt == null)
            .ToListAsync();
        foreach (var token in activeTokens)
            token.RevokedAt = DateTime.UtcNow;

        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> AdminUpdateAsync(int id, string firstName, string lastName, string email, string phone)
    {
        var user = await _uow.Users.GetByIdAsync(id);
        if (user is null) return ServiceResult.Fail("User not found.");

        var validation = await ValidateContactAsync(phone, email, id);
        if (!validation.Success) return validation;

        user.FirstName = firstName.Trim();
        user.LastName = lastName.Trim();
        user.EmailAddress = email.Trim();
        user.PhoneNumber = phone.Trim();
        _uow.Users.Update(user);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> ToggleStatusAsync(int id)
    {
        var user = await _uow.Users.GetByIdAsync(id);
        if (user is null) return ServiceResult.Fail("User not found.");
        user.Status = user.Status == UserStatus.Active ? UserStatus.Blocked : UserStatus.Active;
        _uow.Users.Update(user);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> DeleteAsync(int id)
    {
        var user = await _uow.Users.GetByIdAsync(id);
        if (user is null) return ServiceResult.Fail("User not found.");
        _uow.Users.Remove(user);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    private async Task<ServiceResult> ValidateContactAsync(string phone, string email, int userId)
    {
        if (!PhoneRegex().IsMatch(phone))
            return ServiceResult.Fail("Phone number must be 10 digits starting with 077, 078, or 079.");
        if (!EmailRegex().IsMatch(email))
            return ServiceResult.Fail("Invalid email format.");
        if (await _uow.Users.AnyAsync(u => u.PhoneNumber == phone && u.Id != userId))
            return ServiceResult.Fail("This phone number is already used.");
        if (await _uow.Users.AnyAsync(u => u.EmailAddress == email && u.Id != userId))
            return ServiceResult.Fail("This email address is already used.");
        return ServiceResult.Ok();
    }
}
