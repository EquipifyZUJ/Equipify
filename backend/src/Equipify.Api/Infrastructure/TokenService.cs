using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Service.Settings;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Equipify.Api.Infrastructure;

public class AuthTokens
{
    public string AccessToken { get; init; } = string.Empty;
    public DateTime AccessTokenExpiresAt { get; init; }

    /// <summary>Null for admin logins (admin sessions are not refreshable).</summary>
    public string? RefreshToken { get; init; }
}

/// <summary>Issues JWT access tokens and opaque refresh tokens (stored hashed).</summary>
public interface ITokenService
{
    Task<AuthTokens> IssueForUserAsync(User user);
    Task<AuthTokens> IssueForAdminAsync(string username);

    /// <summary>Validates a refresh token, revokes it and returns its owner.</summary>
    Task<User?> RotateRefreshTokenAsync(string refreshToken);

    /// <summary>Issues a fresh refresh token for an already-authenticated user.</summary>
    Task<string> NewRefreshTokenAsync(int userId);
}

public class TokenService : ITokenService
{
    private readonly IUnitOfWork _uow;
    private readonly JwtSettings _jwt;
    private readonly AdminSettings _admin;

    public TokenService(IUnitOfWork uow, IOptions<JwtSettings> jwt, IOptions<AdminSettings> admin)
    {
        _uow = uow;
        _jwt = jwt.Value;
        _admin = admin.Value;
    }

    public async Task<AuthTokens> IssueForUserAsync(User user)
    {
        var expires = DateTime.UtcNow.AddMinutes(_jwt.AccessTokenMinutes);
        var token = CreateToken(
            subject: user.Id.ToString(),
            name: user.FullName,
            role: "User",
            expiresAt: expires);

        var refresh = await NewRefreshTokenAsync(user.Id);
        return new AuthTokens { AccessToken = token, AccessTokenExpiresAt = expires, RefreshToken = refresh };
    }

    public Task<AuthTokens> IssueForAdminAsync(string username)
    {
        var expires = DateTime.UtcNow.AddMinutes(_jwt.AdminAccessTokenMinutes);
        var token = CreateToken(
            subject: "admin",
            name: username,
            role: "Admin",
            expiresAt: expires);

        return Task.FromResult(new AuthTokens { AccessToken = token, AccessTokenExpiresAt = expires });
    }

    public async Task<User?> RotateRefreshTokenAsync(string refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken)) return null;

        var hash = Hash(refreshToken);
        var stored = await _uow.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash);
        if (stored is null || !stored.IsActive) return null;

        stored.RevokedAt = DateTime.UtcNow; // single use
        await _uow.SaveChangesAsync();

        return await _uow.Users.GetByIdAsync(stored.UserId);
    }

    public async Task<string> NewRefreshTokenAsync(int userId)
    {
        // 64 random bytes -> URL-safe string.
        var raw = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        await _uow.RefreshTokens.AddAsync(new RefreshToken
        {
            UserId = userId,
            TokenHash = Hash(raw),
            ExpiresAt = DateTime.UtcNow.AddDays(_jwt.RefreshTokenDays)
        });
        await _uow.SaveChangesAsync();
        return raw;
    }

    private string CreateToken(string subject, string name, string role, DateTime expiresAt)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, subject),
            new(ClaimTypes.NameIdentifier, subject),
            new(ClaimTypes.Name, name),
            new(ClaimTypes.Role, role),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.SecretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAt,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string Hash(string value)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
}
