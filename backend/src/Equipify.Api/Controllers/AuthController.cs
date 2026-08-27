using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using System.Security.Claims;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IUserService _users;
    private readonly IEmailService _email;
    private readonly IAdminAuthService _adminAuth;
    private readonly ITokenService _tokens;
    private readonly IOtpService _otp;

    public AuthController(IUserService users, IEmailService email, IAdminAuthService adminAuth, ITokenService tokens, IOtpService otp)
    {
        _users = users;
        _email = email;
        _adminAuth = adminAuth;
        _tokens = tokens;
        _otp = otp;
    }

    /// <summary>Sends an OTP to the given phone number (for registration or password reset).</summary>
    [HttpPost("send-otp")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> SendOtp(SendAuthOtpRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
            return BadRequest(new { error = "Phone number is required." });

        try
        {
            var code = await _otp.IssueOtpAsync(request.PhoneNumber);
            return Ok(new OtpSentResponse(true, 60, code));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>Checks if an email is already registered.</summary>
    [HttpGet("check-email")]
    public async Task<IActionResult> CheckEmail([FromQuery] string email)
        => Ok(new { exists = await _users.EmailExistsAsync(email ?? string.Empty) });

    /// <summary>Checks if a phone number is already registered.</summary>
    [HttpGet("check-phone")]
    public async Task<IActionResult> CheckPhone([FromQuery] string phone)
        => Ok(new { exists = await _users.PhoneExistsAsync(phone ?? string.Empty) });

    /// <summary>Registers a new user account (OTP verification required).</summary>
    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Register(RegisterRequest request)
    {
        // Verify OTP
        if (string.IsNullOrWhiteSpace(request.OtpCode) || !_otp.Verify(request.PhoneNumber, request.OtpCode))
            return BadRequest(new { error = "Invalid or expired verification code." });

        var result = await _users.RegisterAsync(new RegisterDto
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            EmailAddress = request.EmailAddress,
            PhoneNumber = request.PhoneNumber,
            Password = request.Password
        });

        if (!result.Success) return ApiResults.FromResult(result);

        await _email.SendWelcomeAsync(request.EmailAddress, $"{request.FirstName} {request.LastName}");
        var user = await _users.AuthenticateAsync(request.PhoneNumber, request.Password);
        return Ok(UserDto.From(user!));
    }

    /// <summary>Authenticates a user and returns JWT + refresh tokens.</summary>
    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var user = await _users.AuthenticateAsync(request.PhoneNumber ?? string.Empty, request.Password ?? string.Empty);
        if (user is null)
            return Unauthorized(new { error = "Invalid phone number or password." });

        var tokens = await _tokens.IssueForUserAsync(user);
        return Ok(new AuthResponse(tokens.AccessToken, tokens.AccessTokenExpiresAt, tokens.RefreshToken, UserDto.From(user)));
    }

    /// <summary>Authenticates the administrator (credentials from secure config).</summary>
    [HttpPost("admin-login")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> AdminLogin(AdminLoginRequest request)
    {
        if (!_adminAuth.ValidateCredentials(request.Username ?? string.Empty, request.Password ?? string.Empty))
            return Unauthorized(new { error = "Invalid username or password." });

        var tokens = await _tokens.IssueForAdminAsync(_adminAuth.AdminUsername);
        return Ok(new AuthResponse(tokens.AccessToken, tokens.AccessTokenExpiresAt, null, null));
    }

    /// <summary>Sends OTP for password reset.</summary>
    [HttpPost("forgot-password")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request)
    {
        var user = await _users.GetByPhoneAsync(request.PhoneNumber ?? string.Empty);
        if (user is null)
            return BadRequest(new { error = "No account found with this phone number." });

        try
        {
            var code = await _otp.IssueOtpAsync(request.PhoneNumber!);
            return Ok(new OtpSentResponse(true, 60, code));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>Resets password after OTP verification.</summary>
    [HttpPost("reset-password")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request)
    {
        if (!_otp.Verify(request.PhoneNumber ?? string.Empty, request.OtpCode ?? string.Empty))
            return BadRequest(new { error = "Invalid or expired verification code." });

        var result = await _users.ResetPasswordAsync(new ResetPasswordDto
        {
            PhoneNumber = request.PhoneNumber,
            OtpCode = request.OtpCode,
            NewPassword = request.NewPassword
        });

        return result.Success ? Ok(new { message = "Password reset successfully." }) : ApiResults.FromResult(result);
    }

    /// <summary>Exchanges a valid refresh token for a new token pair.</summary>
    [HttpPost("refresh")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Refresh(RefreshRequest request)
    {
        var user = await _tokens.RotateRefreshTokenAsync(request.RefreshToken);
        if (user is null || user.Status != UserStatus.Active)
            return Unauthorized(new { error = "Session expired. Please sign in again." });

        var tokens = await _tokens.IssueForUserAsync(user);
        return Ok(new AuthResponse(tokens.AccessToken, tokens.AccessTokenExpiresAt, tokens.RefreshToken, UserDto.From(user)));
    }

    /// <summary>Revokes the supplied refresh token.</summary>
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(RefreshRequest request)
    {
        await _tokens.RotateRefreshTokenAsync(request.RefreshToken); // marks it revoked if valid
        return NoContent();
    }

    /// <summary>Returns the currently authenticated user's profile.</summary>
    [Authorize(Roles = "User")]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var user = await _users.GetByIdAsync(CurrentUserId);
        return user is null ? NotFound() : Ok(UserDto.From(user));
    }

    /// <summary>Updates the authenticated user's profile.</summary>
    [Authorize(Roles = "User")]
    [HttpPut("me")]
    public async Task<IActionResult> UpdateMe(UpdateProfileDto dto)
    {
        dto.UserId = CurrentUserId;
        var result = await _users.UpdateProfileAsync(dto);
        if (!result.Success) return ApiResults.FromResult(result);

        var user = await _users.GetByIdAsync(CurrentUserId);
        return Ok(UserDto.From(user!));
    }

    /// <summary>Changes the password (requires the current password).</summary>
    [Authorize(Roles = "User")]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request)
    {
        var result = await _users.ChangePasswordAsync(new ChangePasswordDto
        {
            UserId = CurrentUserId,
            CurrentPassword = request.CurrentPassword,
            NewPassword = request.NewPassword
        });
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
