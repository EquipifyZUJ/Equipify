using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api")]
public class RatingsController : ControllerBase
{
    private readonly IRatingService _ratings;

    public RatingsController(IRatingService ratings) => _ratings = ratings;

    /// <summary>Reviews left for a specific user (as owner).</summary>
    [HttpGet("users/{id:int}/reviews")]
    [AllowAnonymous]
    public async Task<ActionResult<List<ReviewDto>>> UserReviews(int id, [FromQuery] int limit = 20)
        => Ok((await _ratings.GetReviewsForUserAsync(id, limit)).Select(ReviewDto.From).ToList());

    /// <summary>Reviews left for a specific listing.</summary>
    [HttpGet("listings/{id:int}/reviews")]
    [AllowAnonymous]
    public async Task<ActionResult<List<ReviewDto>>> ListingReviews(int id, [FromQuery] int limit = 20)
        => Ok((await _ratings.GetReviewsForListingAsync(id, limit)).Select(ReviewDto.From).ToList());

    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
