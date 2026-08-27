namespace Equipify.Service.Services.Interfaces;

/// <summary>Sends transactional emails (or logs them when SMTP is disabled).</summary>
public interface IEmailService
{
    Task SendAsync(string toEmail, string toName, string subject, string htmlBody);

    Task SendWelcomeAsync(string toEmail, string name);
    Task SendRequestAcceptedAsync(string toEmail, string name, string listingTitle, string ownerPhone, decimal totalCost);
    Task SendRequestRejectedAsync(string toEmail, string name, string listingTitle, string ownerPhone);
}
