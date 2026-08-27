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

var builder = WebApplication.CreateBuilder(args);

// ── CRITICAL: Clear ALL default config sources (they use reloadOnChange=true → inotify crash on Render free tier) ──
// All config comes from environment variables + InMemoryCollection.
builder.Configuration.Sources.Clear();

// ── Parse DATABASE_URL → Npgsql connection string ──
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL") ?? "";
if (string.IsNullOrEmpty(databaseUrl))
    throw new InvalidOperationException("DATABASE_URL environment variable is required.");

var uri = new Uri(databaseUrl);
var userInfo = uri.UserInfo.Split(':');
var port = uri.Port > 0 ? uri.Port : 5432;
var connectionString = $"Host={uri.Host};Port={port};Database={uri.AbsolutePath.TrimStart('/')};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true";

// ── JWT from env vars ──
var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET") ?? "";
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER") ?? "Equipify.Api";
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE") ?? "Equipify.Client";
if (string.IsNullOrEmpty(jwtSecret))
    throw new InvalidOperationException("JWT_SECRET environment variable is required.");

// ── Inject all config as in-memory (zero file watchers) ──
builder.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
{
    ["ConnectionStrings:DefaultConnection"] = connectionString,
    ["Jwt:SecretKey"] = jwtSecret,
    ["Jwt:Issuer"] = jwtIssuer,
    ["Jwt:Audience"] = jwtAudience,
    ["Jwt:AccessTokenMinutes"] = "60",
    ["Jwt:RefreshTokenDays"] = "7",
    ["Jwt:AdminAccessTokenMinutes"] = "120",
    ["Admin:Username"] = Environment.GetEnvironmentVariable("ADMIN_USERNAME") ?? "admin",
    ["Admin:PasswordHash"] = Environment.GetEnvironmentVariable("ADMIN_PASSWORD_HASH") ?? "$2a$11$ORsJkKedISKcQ3oZ0MtX0eH8JK67WxDuA2u.AMA4ibQpe7rZBHiu2",
    ["Otp:ExpiryMinutes"] = "5",
    ["Otp:MaxAttempts"] = "3",
    ["Otp:ResendCooldownSeconds"] = "60",
    ["Otp:EchoCode"] = "true",
    ["Otp:FixedCode"] = "0000",
});

// ── Serilog (console only — no file logging to avoid inotify) ──
builder.Host.UseSerilog((_, lc) => lc
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .MinimumLevel.Override("Microsoft.AspNetCore", Serilog.Events.LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", Serilog.Events.LogEventLevel.Warning));

// ── Kestrel ──
builder.WebHost.ConfigureKestrel(o => o.Limits.MaxRequestBodySize = 35_000_000);

// ── Layers ──
builder.Services.AddDataLayer(connectionString);
builder.Services.AddServiceLayer(builder.Configuration);

// ── JWT settings ──
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IFileStorageService, FileStorageService>();

var jwt = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>()
    ?? throw new InvalidOperationException("Jwt settings missing.");

// ── Auth ──
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidIssuer = jwt.Issuer,
            ValidateAudience = true, ValidAudience = jwt.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SecretKey)),
            ValidateLifetime = true, ClockSkew = TimeSpan.FromSeconds(30)
        };
    });
builder.Services.AddAuthorization();

// ── CORS ──
const string CorsPolicy = "Frontend";
var frontendUrl = Environment.GetEnvironmentVariable("FRONTEND_URL") ?? "";
var corsOrigins = new List<string>
{
    "http://localhost:5173", "http://127.0.0.1:5173",
    "http://localhost:5000", "http://127.0.0.1:5000",
    "https://equipify.onrender.com",
};
if (!string.IsNullOrEmpty(frontendUrl)) corsOrigins.Add(frontendUrl);

builder.Services.AddCors(o => o.AddPolicy(CorsPolicy, p => p
    .WithOrigins(corsOrigins.ToArray()).AllowAnyHeader().AllowAnyMethod()));

// ── Rate limiting ──
builder.Services.AddRateLimiter(options =>
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

// ── Controllers + Swagger ──
builder.Services.AddControllers()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        o.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.CustomSchemaIds(type => type.FullName);
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Equipify API", Version = "v1", Description = "REST API for the Equipify equipment-rental marketplace (JWT secured)." });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization", Type = SecuritySchemeType.Http, Scheme = "bearer",
        BearerFormat = "JWT", In = ParameterLocation.Header,
        Description = "Paste your access token (without the 'Bearer ' prefix)."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }, Array.Empty<string>() }
    });
});

var app = builder.Build();

// ── Migrate + seed ──
using (var scope = app.Services.CreateScope())
{
    var ctx = scope.ServiceProvider.GetRequiredService<EquipifyDbContext>();
    await DbSeeder.SeedAsync(ctx);
}

app.UseForwardedHeaders(new ForwardedHeadersOptions { ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto });
app.UseMiddleware<ExceptionHandlingMiddleware>();

app.Use(async (ctx, next) =>
{
    ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
    ctx.Response.Headers["X-Frame-Options"] = "DENY";
    ctx.Response.Headers["Referrer-Policy"] = "no-referrer";
    await next();
});

app.UseSerilogRequestLogging();
app.UseStaticFiles();

app.UseSwagger();
app.UseSwaggerUI(c => { c.SwaggerEndpoint("/swagger/v1/swagger.json", "Equipify API v1"); c.DocumentTitle = "Equipify API"; });

app.UseCors(CorsPolicy);
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => Results.Redirect("/swagger"));
app.MapControllers();

app.Run();
