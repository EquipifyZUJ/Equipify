using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Equipify.Service.Settings;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using System.Security.Claims;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/requests")]
[Authorize(Roles = "User")]
public class RequestsController : ControllerBase
{
    private readonly IRentalRequestService _requests;
    private readonly IListingService _listings;
    private readonly IUserService _users;
    private readonly IOtpService _otp;
    private readonly IRatingService _ratings;
    private readonly OtpSettings _otpSettings;

    public RequestsController(IRentalRequestService requests, IListingService listings,
        IUserService users, IOtpService otp, IRatingService ratings, IOptions<OtpSettings> otpSettings)
    {
        _requests = requests;
        _listings = listings;
        _users = users;
        _otp = otp;
        _ratings = ratings;
        _otpSettings = otpSettings.Value;
    }

    /// <summary>Sends an OTP to the current user's phone for a rental request.</summary>
    [HttpPost("otp/send")]
    [EnableRateLimiting("otp")]
    [ProducesResponseType(typeof(OtpSentResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SendOtp(SendOtpRequest request)
    {
        var me = await _users.GetByIdAsync(CurrentUserId);
        if (me is null) return Unauthorized();

        var listing = await _listings.GetDetailsAsync(request.ListingId);
        if (listing is null) return NotFound(new { error = "Listing not found." });
        if (listing.OwnerId == CurrentUserId)
            return BadRequest(new { error = "You cannot request your own listing." });

        string? devCode = null;
        try { devCode = await _otp.IssueOtpAsync(me.PhoneNumber); }
        catch (InvalidOperationException ex) { return Conflict(new { error = ex.Message }); }

        // EchoCode=true only in development; the code also appears in server logs.
        return Ok(new OtpSentResponse(true, _otpSettings.ResendCooldownSeconds, devCode));
    }

    /// <summary>Creates a rental request after OTP verification.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(CreateRentalRequestInput input)
    {
        var me = await _users.GetByIdAsync(CurrentUserId);
        if (me is null) return Unauthorized();

        if (!_otp.Verify(me.PhoneNumber, input.OtpCode ?? string.Empty))
            return BadRequest(new { error = "Invalid or expired OTP code. Please request a new one." });

        var result = await _requests.CreateAsync(new RentalRequestDto
        {
            ListingId = input.ListingId,
            UserId = CurrentUserId,
            FromDate = input.FromDate,
            ToDate = input.ToDate,
            FromTime = input.FromTime,
            ToTime = input.ToTime,
            OtpVerified = true
        });

        return result.Success
            ? Created($"/api/requests/mine", new { id = result.Value })
            : ApiResults.FromResult(result);
    }

    /// <summary>Rental requests placed by the current user.</summary>
    [HttpGet("mine")]
    public async Task<IActionResult> Mine()
        => Ok((await _requests.GetMyRequestsAsync(CurrentUserId)).Select(RentalRequestResponse.From).ToList());

    /// <summary>Requests received on the user's own listings.</summary>
    [HttpGet("incoming")]
    public async Task<IActionResult> Incoming()
        => Ok((await _requests.GetIncomingForOwnerAsync(CurrentUserId)).Select(RentalRequestResponse.From).ToList());

    /// <summary>Requests on one specific owned listing.</summary>
    [HttpGet("for-listing/{listingId:int}")]
    public async Task<IActionResult> ForListing(int listingId)
        => Ok((await _requests.GetRequestsForListingAsync(listingId, CurrentUserId))
            .Select(RentalRequestResponse.From).ToList());

    /// <summary>Accepts an incoming request (owner only).</summary>
    [HttpPost("{id:int}/accept")]
    public async Task<IActionResult> Accept(int id)
    {
        var result = await _requests.AcceptAsync(id, CurrentUserId);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Rejects an incoming request (owner only).</summary>
    [HttpPost("{id:int}/reject")]
    public async Task<IActionResult> Reject(int id)
    {
        var result = await _requests.RejectAsync(id, CurrentUserId);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Cancels/deletes the user's own request.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await _requests.DeleteAsync(id, CurrentUserId);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Rates an accepted rental (1-5).</summary>
    [HttpPost("{id:int}/rating")]
    public async Task<IActionResult> Rate(int id, SubmitRatingRequest request)
    {
        var result = await _ratings.SubmitAsync(CurrentUserId, id, request.Rating);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
