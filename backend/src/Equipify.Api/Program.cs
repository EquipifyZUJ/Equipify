using System.Text;
using System.Text.Json.Serialization;
using Equipify.Api.Infrastructure;
using Equipify.Api.Services;
using Equipify.Data;
using Equipify.Data.Seed;
using Equipify.Service;
using Equipify.Service.Settings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

// ─────────────────────────────────────────────────────
//  Render free tier inotify limit = 128.
//  WebApplication.CreateBuilder() internally creates
//  FileSystemWatcher → crash on startup.
//  FIX: Use HostBuilder (NOT CreateDefaultBuilder)
//  which does NOT auto-create file watchers.
// ─────────────────────────────────────────────────────

var envName = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production";

// ── Build config WITHOUT file watchers ──
var configBuilder = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
    .AddJsonFile($"appsettings.{envName}.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables();
var config = configBuilder.Build();

// ── Render: DATABASE_URL → Npgsql connection string ──
var connectionString = config.GetConnectionString("DefaultConnection") ?? "";
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
if (!string.IsNullOrEmpty(databaseUrl))
{
    var uri = new Uri(databaseUrl);
    var userInfo = uri.UserInfo.Split(':');
    var port = uri.Port > 0 ? uri.Port : 5432;
    connectionString = $"Host={uri.Host};Port={port};Database={uri.AbsolutePath.TrimStart('/')};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true";
}
if (string.IsNullOrEmpty(connectionString))
    throw new InvalidOperationException("DATABASE_URL is required.");

// ── JWT from env vars ──
var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET") ?? "";
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER") ?? config["Jwt:Issuer"] ?? "Equipify.Api";
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE") ?? config["Jwt:Audience"] ?? "Equipify.Client";
if (string.IsNullOrEmpty(jwtSecret))
    throw new InvalidOperationException("JWT_SECRET environment variable is required.");

// Merge all config into an in-memory dictionary
var configValues = new Dictionary<string, string?>
{
    ["ConnectionStrings:DefaultConnection"] = connectionString,
    ["Jwt:SecretKey"] = jwtSecret,
    ["Jwt:Issuer"] = jwtIssuer,
    ["Jwt:Audience"] = jwtAudience,
    ["Jwt:AccessTokenMinutes"] = config["Jwt:AccessTokenMinutes"] ?? "60",
    ["Jwt:RefreshTokenDays"] = config["Jwt:RefreshTokenDays"] ?? "7",
    ["Jwt:AdminAccessTokenMinutes"] = config["Jwt:AdminAccessTokenMinutes"] ?? "120",
    ["Admin:Username"] = config["Admin:Username"] ?? "admin",
    ["Admin:PasswordHash"] = config["Admin:PasswordHash"] ?? "",
    ["Otp:ExpiryMinutes"] = config["Otp:ExpiryMinutes"] ?? "5",
    ["Otp:MaxAttempts"] = config["Otp:MaxAttempts"] ?? "3",
    ["Otp:ResendCooldownSeconds"] = config["Otp:ResendCooldownSeconds"] ?? "60",
    ["Otp:EchoCode"] = config["Otp:EchoCode"] ?? "true",
    ["Otp:FixedCode"] = config["Otp:FixedCode"] ?? "0000",
};

const string CorsPolicy = "Frontend";

var host = new HostBuilder()
    .ConfigureAppConfiguration((ctx, cfg) =>
    {
        cfg.Sources.Clear();
        cfg.AddInMemoryCollection(configValues);
    })
    .UseSerilog((_, lc) => lc
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .MinimumLevel.Override("Microsoft.AspNetCore", Serilog.Events.LogEventLevel.Warning)
        .MinimumLevel.Override("Microsoft.EntityFrameworkCore", Serilog.Events.LogEventLevel.Warning))
    .ConfigureWebHostDefaults(webBuilder =>
    {
        webBuilder.UseKestrel(o => o.Limits.MaxRequestBodySize = 35_000_000);
        webBuilder.UseUrls("http://0.0.0.0:10000");

        webBuilder.ConfigureServices((ctx, services) =>
        {
            services.AddDataLayer(connectionString);
            services.AddServiceLayer(ctx.Configuration);

            services.Configure<JwtSettings>(ctx.Configuration.GetSection(JwtSettings.SectionName));
            services.AddScoped<ITokenService, TokenService>();
            services.AddScoped<IFileStorageService, FileStorageService>();

            var jwt = ctx.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>()
                ?? throw new InvalidOperationException("Jwt settings missing.");

            services.AddAuthentication(o =>
                {
                    o.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                    o.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
                })
                .AddJwtBearer(o =>
                {
                    o.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true, ValidIssuer = jwt.Issuer,
                        ValidateAudience = true, ValidAudience = jwt.Audience,
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SecretKey)),
                        ValidateLifetime = true, ClockSkew = TimeSpan.FromSeconds(30)
                    };
                });
            services.AddAuthorization();

            var frontendUrl = Environment.GetEnvironmentVariable("FRONTEND_URL") ?? "";
            var corsOrigins = new List<string>
            {
                "http://localhost:5173", "http://127.0.0.1:5173",
                "http://localhost:5000", "http://127.0.0.1:5000",
                "https://equipify.onrender.com",
            };
            if (!string.IsNullOrEmpty(frontendUrl)) corsOrigins.Add(frontendUrl);

            services.AddCors(o => o.AddPolicy(CorsPolicy, p => p
                .WithOrigins(corsOrigins.ToArray()).AllowAnyHeader().AllowAnyMethod()));

            services.AddRateLimiter(options =>
            {
                options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
                options.AddFixedWindowLimiter("auth", l => { l.PermitLimit = 10; l.Window = TimeSpan.FromMinutes(1); l.QueueLimit = 0; });
                options.AddFixedWindowLimiter("otp", l => { l.PermitLimit = 5; l.Window = TimeSpan.FromMinutes(1); l.QueueLimit = 0; });
                options.OnRejected = async (ctx, _) =>
                {
                    ctx.HttpContext.Response.ContentType = "application/json";
                    await ctx.HttpContext.Response.WriteAsJsonAsync(new { error = "Too many requests." });
                };
            });

            services.AddControllers().AddJsonOptions(o =>
            {
                o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
                o.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
            });

            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen(c =>
            {
                c.CustomSchemaIds(type => type.FullName);
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "Equipify API", Version = "v1" });
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization", Type = SecuritySchemeType.Http,
                    Scheme = "bearer", BearerFormat = "JWT", In = ParameterLocation.Header
                });
                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    { new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }, Array.Empty<string>() }
                });
            });
        });

        webBuilder.Configure(app =>
        {
            using var scope = app.ApplicationServices.CreateScope();
            var ctx = scope.ServiceProvider.GetRequiredService<EquipifyDbContext>();
            DbSeeder.SeedAsync(ctx).GetAwaiter().GetResult();

            var webApp = (IApplicationBuilder)app;
            var endpoints = (IEndpointRouteBuilder)app;

            webApp.UseForwardedHeaders(new ForwardedHeadersOptions { ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto });
            webApp.UseMiddleware<ExceptionHandlingMiddleware>();

            webApp.Use(async (ctx, next) =>
            {
                ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
                ctx.Response.Headers["X-Frame-Options"] = "DENY";
                ctx.Response.Headers["Referrer-Policy"] = "no-referrer";
                await next();
            });

            webApp.UseSerilogRequestLogging();
            webApp.UseStaticFiles();

            webApp.UseSwagger();
            webApp.UseSwaggerUI(c => { c.SwaggerEndpoint("/swagger/v1/swagger.json", "Equipify API v1"); c.DocumentTitle = "Equipify API"; });

            webApp.UseCors(CorsPolicy);
            webApp.UseRateLimiter();
            webApp.UseAuthentication();
            webApp.UseAuthorization();

            endpoints.MapGet("/", () => Results.Redirect("/swagger"));
            endpoints.MapControllers();
        });
    })
    .Build();

await host.RunAsync();
