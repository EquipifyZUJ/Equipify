using Equipify.Domain.Entities;
using Equipify.Domain.Enums;

namespace Equipify.Api.Contracts;

// ---------- Auth ----------

public record RegisterRequest(string FirstName, string LastName, string EmailAddress, string PhoneNumber, string Password, string? OtpCode);
public record LoginRequest(string PhoneNumber, string Password);
public record AdminLoginRequest(string Username, string Password);
public record RefreshRequest(string RefreshToken);
public record ChangePasswordRequest(string CurrentPassword, string NewPassword);
public record SendAuthOtpRequest(string PhoneNumber);
public record ForgotPasswordRequest(string PhoneNumber);
public record ResetPasswordRequest(string PhoneNumber, string OtpCode, string NewPassword);

public record AuthResponse(string AccessToken, DateTime ExpiresAtUtc, string? RefreshToken, UserDto? User);
public record UserDto(int Id, string FirstName, string LastName, string Name, string EmailAddress, string PhoneNumber, double? Rating, string Status, DateTime CreatedAt)
{
    public static UserDto From(User u) => new(u.Id, u.FirstName, u.LastName, u.FullName, u.EmailAddress, u.PhoneNumber, u.Rating, u.Status.ToString(), u.CreatedAt);
}

// ---------- Listings ----------

public record ListingDto(
    int Id, string Title, string Description,
    string? MainImage, List<string> Images,
    int CategoryId, string CategoryName,
    string LocationAddress,
    string RentalUnit,
    decimal? CostPerHour, decimal CostPerDay, decimal? CostPerWeek, decimal? CostPerMonth, decimal? CostPerYear,
    int? MinRentalDays, int? MaxRentalDays,
    double Latitude, double Longitude,
    string Status, DateTime CreatedAt,
    OwnerDto? Owner)
{
    public static ListingDto From(Listing l) => new(
        l.Id, l.Title, l.Description,
        l.MainImage,
        l.Images.Select(i => i.ImagePath).ToList(),
        l.CategoryId, l.Category?.Name ?? string.Empty,
        l.LocationAddress,
        l.RentalUnit,
        l.CostPerHour, l.CostPerDay, l.CostPerWeek, l.CostPerMonth, l.CostPerYear,
        l.MinRentalDays, l.MaxRentalDays,
        l.Latitude, l.Longitude,
        l.Status.ToString(), l.CreatedAt,
        l.Owner is null ? null : new OwnerDto(l.Owner.Id, l.Owner.FullName, l.Owner.Rating));
}

/// <summary>Owner summary; phone is attached only for authenticated viewers.</summary>
public record OwnerDto(int Id, string Name, double? Rating)
{
    public int TotalRates { get; init; }
    public OwnerDto WithPhone(User owner) => this with { };
}

public record ListingSummaryDto(
    int Id, string Title, string? MainImage,
    string RentalUnit,
    decimal? CostPerHour, decimal CostPerDay, decimal? CostPerWeek, decimal? CostPerMonth,
    int? MinRentalDays, int? MaxRentalDays,
    string LocationAddress,
    double Latitude, double Longitude,
    int CategoryId, string CategoryName,
    string Status)
{
    public static ListingSummaryDto From(Listing l) => new(
        l.Id, l.Title, l.MainImage,
        l.RentalUnit,
        l.CostPerHour, l.CostPerDay, l.CostPerWeek, l.CostPerMonth,
        l.MinRentalDays, l.MaxRentalDays,
        l.LocationAddress, l.Latitude, l.Longitude,
        l.CategoryId, l.Category?.Name ?? string.Empty,
        l.Status.ToString());
}

public record PagedResponse<T>(List<T> Items, int Page, int PageSize, int TotalCount, int TotalPages);

public record MapMarkerDto(int Id, string Title, string? Image, decimal CostPerDay, string LocationAddress, double Latitude, double Longitude)
{
    public static MapMarkerDto From(Listing l) => new(l.Id, l.Title, l.MainImage, l.CostPerDay, l.LocationAddress, l.Latitude, l.Longitude);
}

public record SetListingStatusRequest(string Status); // "Active" | "Inactive"

// ---------- Categories ----------

public record CategoryDto(int Id, string Name, string? NameAr, string? Picture)
{
    public static CategoryDto From(Category c) => new(c.Id, c.Name, c.NameAr, c.Picture);
}
public record SaveCategoryRequest(string Name);

// ---------- Requests / OTP / Ratings ----------

public record SendOtpRequest(int ListingId);
public record OtpSentResponse(bool Sent, int CooldownSeconds, string? DevCode);

public record CreateRentalRequestInput(
    int ListingId, DateOnly FromDate, DateOnly ToDate,
    TimeOnly FromTime, TimeOnly ToTime, string OtpCode);

public record RentalRequestResponse(
    int Id,
    int ListingId, string ListingTitle, string? ListingImage, decimal CostPerDay,
    RenterDto Renter,
    DateOnly FromDate, DateOnly ToDate, TimeOnly FromTime, TimeOnly ToTime,
    decimal TotalCost, string Status, bool HasRating, DateTime CreatedAt)
{
    public static RentalRequestResponse From(RentalRequest r) => new(
        r.Id,
        r.ListingId, r.Listing?.Title ?? string.Empty, r.Listing?.MainImage, r.Listing?.CostPerDay ?? 0,
        new RenterDto(r.UserId, r.User?.FullName ?? string.Empty, r.User?.PhoneNumber ?? string.Empty),
        r.FromDate, r.ToDate, r.FromTime, r.ToTime,
        r.TotalCost, r.Status.ToString(), r.Rating is not null, r.CreatedAt);
}

public record RenterDto(int Id, string Name, string PhoneNumber);

public record SubmitRatingRequest(double Rating);

public record ReviewDto(int Id, int RenterId, string RenterName, int ListingId, string ListingTitle, double Rating, DateTime CreatedAt)
{
    public static ReviewDto From(UserRating r) => new(
        r.Id, r.RenterId, r.Renter?.FullName ?? string.Empty,
        r.ListingId, r.Listing?.Title ?? string.Empty,
        r.Rating, r.CreatedAt);
}

// ---------- Admin ----------

public record UpdateUserRequest(string FirstName, string LastName, string EmailAddress, string PhoneNumber);

public record DashboardStatsDto(int Users, int Listings, int ActiveListings, int PendingListings,
    int Categories, int Requests, int PendingRequests)
{
    public static DashboardStatsDto From(Service.Models.DashboardStats s) =>
        new(s.Users, s.Listings, s.ActiveListings, s.PendingListings, s.Categories, s.Requests, s.PendingRequests);
}
