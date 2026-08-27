using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Equipify.Data.Seed;

/// <summary>Applies migrations and seeds baseline demo data on startup.</summary>
public static class DbSeeder
{
    public static async Task SeedAsync(EquipifyDbContext context)
    {
        // Code-first schema creation. If migrations were generated
        // (dotnet ef migrations add ...) they are applied; otherwise the
        // schema is created directly from the model so the app runs as-is.
        if (context.Database.GetMigrations().Any())
            await context.Database.MigrateAsync();
        else
            await context.Database.EnsureCreatedAsync();

        // ---- Categories ----
        if (!await context.Categories.AnyAsync())
        {
            context.Categories.AddRange(
                new Category { Name = "Electronics", NameAr = "إلكترونيات", Picture = "/images/categories/Electronics.webp" },
                new Category { Name = "Computers", NameAr = "أجهزة كمبيوتر", Picture = "/images/categories/ComputerAndLaptops.webp" },
                new Category { Name = "Services", NameAr = "خدمات", Picture = "/images/categories/Services.webp" },
                new Category { Name = "Vehicles", NameAr = "مركبات", Picture = "/images/categories/Autos.webp" },
                new Category { Name = "Motorcycles", NameAr = "دراجات نارية", Picture = "/images/categories/MotorcyclesHome.webp" },
                new Category { Name = "Video Games", NameAr = "ألعاب فيديو", Picture = "/images/categories/Gaming.webp" },
                new Category { Name = "Fitness Machines", NameAr = "أجهزة رياضية", Picture = "/images/categories/Sports.webp" },
                new Category { Name = "Real Estate", NameAr = "عقارات", Picture = "/images/categories/Properties.webp" },
                new Category { Name = "Equipments", NameAr = "معدات", Picture = "/images/categories/BusinessIndustrial.webp" }
            );
            await context.SaveChangesAsync();
        }

        // ---- Users ----
        if (!await context.Users.AnyAsync())
        {
            string hash = BCrypt.Net.BCrypt.HashPassword("123456");
            context.Users.AddRange(
                new User { FirstName = "Mahmoud", LastName = "Sanazmi", EmailAddress = "Mahmoud@example.com", PhoneNumber = "0790666835", PasswordHash = hash, Status = UserStatus.Active },
                new User { FirstName = "Mohammad", LastName = "Ali", EmailAddress = "Mohammad@example.com", PhoneNumber = "0797161832", PasswordHash = hash, Status = UserStatus.Active },
                new User { FirstName = "Khaled", LastName = "Ahmad", EmailAddress = "Khaled@example.com", PhoneNumber = "0796908650", PasswordHash = hash, Status = UserStatus.Active, Rating = 4 }
            );
            await context.SaveChangesAsync();
        }

        // ---- Listings ----
        if (!await context.Listings.AnyAsync())
        {
            var vehicles = await context.Categories.FirstAsync(c => c.Name == "Vehicles");
            var computers = await context.Categories.FirstAsync(c => c.Name == "Computers");
            var mohammad = await context.Users.FirstAsync(u => u.PhoneNumber == "0797161832");
            var Khaled = await context.Users.FirstAsync(u => u.PhoneNumber == "0796908650");

            context.Listings.AddRange(
                new Listing
                {
                    OwnerId = mohammad.Id,
                    Title = "10,000 lbs. Tilt Trailer",
                    Description = "Transport your off-road vehicles, riding mowers and other work equipment to and from jobsites with this 10,000-pound tilt trailer. Comes with an adjustable 3-inch ball-style Pintle hitch and a single hydraulic cylinder for smooth loading and unloading.",
                    MainImage = "/images/samples/trailer.jpeg",
                    CategoryId = vehicles.Id,
                    LocationAddress = "Irbid",
                    CostPerDay = 50m,
                    Latitude = 32.5556,
                    Longitude = 35.8500,
                    Status = ListingStatus.Active,
                    Images = new List<ListingImage>
                    {
                        new() { ImagePath = "/images/samples/trailer.jpeg" },
                        new() { ImagePath = "/images/samples/trailer2.jpeg" }
                    }
                },
                new Listing
                {
                    OwnerId = mohammad.Id,
                    Title = "Canon EOS M50 Mirrorless Camera",
                    Description = "Capture stunning photos and 4K video with the Canon EOS M50. 24.1MP sensor, fast autofocus, lightweight and beginner-friendly. Perfect for events, content creation and travel.",
                    MainImage = "/images/samples/canon.jpg",
                    CategoryId = computers.Id,
                    LocationAddress = "Amman",
                    Latitude = 31.9539,
                    Longitude = 35.9106,
                    CostPerDay = 16m,
                    Status = ListingStatus.Active,
                    Images = new List<ListingImage>
                    {
                        new() { ImagePath = "/images/samples/canon.jpg" },
                        new() { ImagePath = "/images/samples/canon2.jpg" },
                        new() { ImagePath = "/images/samples/canon3.jpg" }
                    }
                },
                new Listing
                {
                    OwnerId = Khaled.Id,
                    Title = "Lenovo ThinkPad X1 Carbon",
                    Description = "Ultra-light premium business laptop. 10th Gen Intel Core i7, 16GB RAM, 512GB SSD, carbon-fiber chassis and long battery life. Ideal for professionals and students.",
                    MainImage = "/images/samples/lenovo.jpg",
                    CategoryId = computers.Id,
                    LocationAddress = "Zarqa",
                    CostPerDay = 20m,
                    Latitude = 32.0728,
                    Longitude = 36.0880,
                    Status = ListingStatus.Active,
                    Images = new List<ListingImage>
                    {
                        new() { ImagePath = "/images/samples/lenovo.jpg" },
                        new() { ImagePath = "/images/samples/lenovo2.jpg" },
                        new() { ImagePath = "/images/samples/lenovo3.jpg" }
                    }
                },
                new Listing
                {
                    OwnerId = Khaled.Id,
                    Title = "BMW M5",
                    Description = "Powerful sports sedan available for daily rental. Well maintained, low mileage and a thrilling drive.",
                    MainImage = "/images/samples/bmw.jpg",
                    CategoryId = vehicles.Id,
                    LocationAddress = "Amman",
                    Latitude = 31.9700,
                    Longitude = 35.8900,
                    CostPerDay = 99.99m,
                    Status = ListingStatus.Active,
                    Images = new List<ListingImage>
                    {
                        new() { ImagePath = "/images/samples/bmw.jpg" },
                        new() { ImagePath = "/images/samples/bmw2.jpg" },
                        new() { ImagePath = "/images/samples/bmw3.jpg" }
                    }
                }
            );
            await context.SaveChangesAsync();
        }
    }
}
