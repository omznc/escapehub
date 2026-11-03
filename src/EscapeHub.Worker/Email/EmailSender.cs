using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using EscapeHub.Worker.Configuration;

namespace EscapeHub.Worker.Email;

public class EmailSender
{
    private readonly SmtpOptions _options;
    private readonly ILogger<EmailSender> _logger;

    public EmailSender(SmtpOptions options, ILogger<EmailSender> logger)
    {
        _options = options;
        _logger = logger;
    }

    public async Task SendAsync(string toEmail, string toName, string subject, string text, CancellationToken cancellationToken = default)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_options.FromName, _options.FromEmail));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = subject;
        message.Body = new TextPart("plain") { Text = text };

        using var client = new SmtpClient();
        var security = _options.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
        await client.ConnectAsync(_options.Host, _options.Port, security, cancellationToken);
        if (!string.IsNullOrEmpty(_options.Username))
            await client.AuthenticateAsync(_options.Username, _options.Password ?? string.Empty, cancellationToken);
        await client.SendAsync(message, cancellationToken);
        await client.DisconnectAsync(true, cancellationToken);
        _logger.LogInformation("Sent email {Subject}", subject);
    }
}
