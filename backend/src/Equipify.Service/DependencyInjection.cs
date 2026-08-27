using Equipify.Service.Services;
using Equipify.Service.Services.Interfaces;
using Equipify.Service.Settings;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Equipify.Service;

/// <summary>Registers business-layer services and binds configuration settings.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddServiceLayer(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<AdminSettings>(configuration.GetSection(AdminSettings.SectionName));
        services.Configure<OtpSettings>(configuration.GetSection(OtpSettings.SectionName));
        services.Configure<EmailSettings>(configuration.GetSection(EmailSettings.SectionName));

        services.AddScoped<IUserService, UserService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IListingService, ListingService>();
        services.AddScoped<IRentalRequestService, RentalRequestService>();
        services.AddScoped<IRatingService, RatingService>();
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddSingleton<IOtpService, OtpService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddSingleton<IAdminAuthService, AdminAuthService>();

        return services;
    }
}
