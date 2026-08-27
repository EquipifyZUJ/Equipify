using System.Net;
using System.Net.Mail;
using Equipify.Service.Services.Interfaces;
using Equipify.Service.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Equipify.Service.Services;

/// <summary>
/// Sends email via SMTP when Email:Enabled is true (e.g. a free Gmail account
/// using an App Password). When disabled, emails are logged instead of sent so
/// the app runs with no credentials.
/// </summary>
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IOptions<EmailSettings> settings, ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation("[Email disabled] To: {Email} ({Name}) | Subject: {Subject}", toEmail, toName, subject);
            return;
        }

        try
        {
            using var message = new MailMessage
            {
                From = new MailAddress(_settings.FromEmail, _settings.FromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };
            message.To.Add(new MailAddress(toEmail, toName));

            using var client = new SmtpClient(_settings.Host, _settings.Port)
            {
                EnableSsl = _settings.UseSsl,
                Credentials = new NetworkCredential(_settings.Username, _settings.Password)
            };

            await client.SendMailAsync(message);
            _logger.LogInformation("Email sent to {Email} | Subject: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            // Never let a failed email break the main flow.
            _logger.LogError(ex, "Failed to send email to {Email}", toEmail);
        }
    }

    public Task SendWelcomeAsync(string toEmail, string name)
        => SendAsync(toEmail, name, "Welcome to Equipify!",
            $"<h2>Welcome aboard, {name}!</h2><p>Thanks for joining Equipify. You can now list your equipment and rent from others.</p>");

    public Task SendRequestAcceptedAsync(string toEmail, string name, string listingTitle, string ownerPhone, decimal totalCost)
        => SendAsync(toEmail, name, "Your rental request is approved!",
            $"<h2>Good news, {name}!</h2><p>Your rental request for <strong>{listingTitle}</strong> has been approved.</p>" +
            $"<p>Total cost: <strong>{totalCost:0.00} JOD</strong>.</p><p>Contact the owner on {ownerPhone} to arrange pickup.</p>");

    public Task SendRequestRejectedAsync(string toEmail, string name, string listingTitle, string ownerPhone)
        => SendAsync(toEmail, name, "Your rental request was rejected",
            $"<h2>Hi {name},</h2><p>Unfortunately your rental request for <strong>{listingTitle}</strong> was rejected.</p>" +
            $"<p>You can contact the owner on {ownerPhone} for more details.</p>");
}
