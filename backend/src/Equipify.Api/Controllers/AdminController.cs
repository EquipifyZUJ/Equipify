using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Api.Services;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IDashboardService _dashboard;
    private readonly IUserService _users;
    private readonly IListingService _listings;
    private readonly ICategoryService _categories;
    private readonly IRentalRequestService _requests;
    private readonly IFileStorageService _files;

    public AdminController(IDashboardService dashboard, IUserService users, IListingService listings,
        ICategoryService categories, IRentalRequestService requests, IFileStorageService files)
    {
        _dashboard = dashboard;
        _users = users;
        _listings = listings;
        _categories = categories;
        _requests = requests;
        _files = files;
    }

    // ---------- Dashboard ----------

    /// <summary>Aggregate counts for the admin dashboard.</summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardStatsDto>> Dashboard()
        => Ok(DashboardStatsDto.From(await _dashboard.GetStatsAsync()));

    // ---------- Users ----------

    /// <summary>All users.</summary>
    [HttpGet("users")]
    public async Task<ActionResult<List<UserDto>>> Users()
        => Ok((await _users.GetAllAsync()).Select(UserDto.From).ToList());

    /// <summary>Updates a user's contact info (duplicate email/phone validated).</summary>
    [HttpPut("users/{id:int}")]
    public async Task<IActionResult> UpdateUser(int id, UpdateUserRequest request)
    {
        var result = await _users.AdminUpdateAsync(id, request.FirstName, request.LastName, request.EmailAddress, request.PhoneNumber);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Blocks/unblocks a user.</summary>
    [HttpPost("users/{id:int}/toggle-status")]
    public async Task<IActionResult> ToggleUserStatus(int id)
    {
        var result = await _users.ToggleStatusAsync(id);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Deletes a user and all their data.</summary>
    [HttpDelete("users/{id:int}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var result = await _users.DeleteAsync(id);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    // ---------- Listings ----------

    /// <summary>All listings including pending/inactive.</summary>
    [HttpGet("listings")]
    public async Task<ActionResult<List<ListingSummaryDto>>> Listings()
        => Ok((await _listings.GetAllAsync()).Select(ListingSummaryDto.From).ToList());

    /// <summary>Approves a pending listing (sets it Active).</summary>
    [HttpPost("listings/{id:int}/approve")]
    public async Task<IActionResult> ApproveListing(int id)
    {
        var result = await _listings.SetStatusAsync(id, Domain.Enums.ListingStatus.Active);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Deactivates a listing.</summary>
    [HttpPost("listings/{id:int}/deactivate")]
    public async Task<IActionResult> DeactivateListing(int id)
    {
        var result = await _listings.SetStatusAsync(id, Domain.Enums.ListingStatus.Inactive);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Deletes any listing and its images.</summary>
    [HttpDelete("listings/{id:int}")]
    public async Task<IActionResult> DeleteListing([FromServices] ListingsControllerHelper helper, int id)
    {
        var result = await _listings.DeleteAsync(id);
        if (!result.Success) return ApiResults.FromResult(result);

        if (result is ServiceResult<List<string>> { Value: not null } withPaths)
            helper.DeleteFiles(withPaths.Value, HttpContext.RequestServices);
        return NoContent();
    }

    // ---------- Categories ----------

    /// <summary>Creates a category (optional image upload).</summary>
    [HttpPost("categories")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> CreateCategory([FromForm] string name, IFormFile? picture)
    {
        var path = picture is null ? null : (await _files.SaveImagesAsync(new[] { picture }, "categories")).FirstOrDefault();
        var result = await _categories.CreateAsync(name, path);
        return result.Success ? Created($"/api/categories/{result.Value}", new { id = result.Value }) : ApiResults.FromResult(result);
    }

    /// <summary>Updates a category (optional new image).</summary>
    [HttpPut("categories/{id:int}")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UpdateCategory(int id, [FromForm] string name, IFormFile? picture)
    {
        var path = picture is null ? null : (await _files.SaveImagesAsync(new[] { picture }, "categories")).FirstOrDefault();
        var result = await _categories.UpdateAsync(id, name, path);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    /// <summary>Deletes a category.</summary>
    [HttpDelete("categories/{id:int}")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        var result = await _categories.DeleteAsync(id);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }

    // ---------- Requests ----------

    /// <summary>All rental requests across the marketplace.</summary>
    [HttpGet("requests")]
    public async Task<ActionResult<List<RentalRequestDto>>> Requests()
        => Ok((await _requests.GetAllAsync()).Select(RentalRequestResponse.From).ToList());

    /// <summary>Deletes any rental request.</summary>
    [HttpDelete("requests/{id:int}")]
    public async Task<IActionResult> DeleteRequest(int id)
    {
        var result = await _requests.DeleteAsync(id, isAdmin: true);
        return result.Success ? NoContent() : ApiResults.FromResult(result);
    }
}

/// <summary>Small helper so file cleanup logic is shared without exposing it on the controller.</summary>
public class ListingsControllerHelper
{
    public void DeleteFiles(IEnumerable<string> webPaths, IServiceProvider services)
    {
        var env = services.GetRequiredService<IWebHostEnvironment>();
        var wwwroot = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        foreach (var path in webPaths)
        {
            var safe = path.Replace('\\', '/').TrimStart('/');
            if (!safe.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase)) continue;
            try { System.IO.File.Delete(Path.Combine(wwwroot, safe)); }
            catch { /* best effort */ }
        }
    }
}
