using Equipify.Domain.Entities;
using Equipify.Domain.Enums;
using Equipify.Service.Models;
using Microsoft.AspNetCore.Mvc;

namespace Equipify.Api.Infrastructure;

/// <summary>Maps thrown exceptions / failures to RFC7807 ProblemDetails responses.</summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            var (status, title) = ex switch
            {
                InvalidOperationException => (StatusCodes.Status409Conflict, "Request rejected"),
                UnauthorizedAccessException => (StatusCodes.Status403Forbidden, "Forbidden"),
                _ => (StatusCodes.Status500InternalServerError, "Server error")
            };

            if (status == StatusCodes.Status500InternalServerError)
                _logger.LogError(ex, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
            else
                _logger.LogWarning("{Title}: {Message} ({Method} {Path})", title, ex.Message, context.Request.Method, context.Request.Path);

            context.Response.StatusCode = status;
            context.Response.ContentType = "application/problem+json";
            await context.Response.WriteAsJsonAsync(new
            {
                type = $"https://httpstatuses.com/{status}",
                title,
                status,
                detail = status == StatusCodes.Status500InternalServerError ? "An unexpected error occurred." : ex.Message,
                instance = context.Request.Path
            });
        }
    }
}

/// <summary>Standard error body shape returned by service-layer failures.</summary>
public static class ApiResults
{
    public static IActionResult FromResult(ServiceResult result) =>
        new ObjectResult(new { error = result.Error }) { StatusCode = StatusCodes.Status400BadRequest };
}
