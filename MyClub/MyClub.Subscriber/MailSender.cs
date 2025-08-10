using MailKit.Net.Smtp;
using MimeKit;
using MyClub.Model;
using MailKit.Security;

namespace MyClub.Subscriber
{
    public static class MailSender
    {
        public static async Task<bool> SendEmail(EmailMessage mailObj)
        {
            if (mailObj == null) return false;

            string fromAddress = Environment.GetEnvironmentVariable("_fromAddress")
                                    ?? Environment.GetEnvironmentVariable("SMTP_USERNAME")
                                    ?? "";
            string password = Environment.GetEnvironmentVariable("_password")
                                    ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD")
                                    ?? string.Empty;
            string host = Environment.GetEnvironmentVariable("_host")
                                    ?? Environment.GetEnvironmentVariable("SMTP_SERVER")
                                    ?? "smtp.gmail.com";
            int port = int.Parse(
                Environment.GetEnvironmentVariable("_port")
                ?? Environment.GetEnvironmentVariable("SMTP_PORT")
                ?? "587");
            bool enableSSL = bool.Parse(Environment.GetEnvironmentVariable("_enableSSL") ?? "true");
            string displayName = Environment.GetEnvironmentVariable("_displayName")
                                    ?? Environment.GetEnvironmentVariable("SMTP_SENDER_NAME")
                                    ?? "no-reply";

            if (string.IsNullOrWhiteSpace(fromAddress) || string.IsNullOrWhiteSpace(password))
            {
                Console.WriteLine("Missing SMTP credentials. Set _fromAddress/_password or SMTP_USERNAME/SMTP_PASSWORD.");
                return false;
            }

            var email = new MimeMessage();
            email.From.Add(new MailboxAddress(displayName, fromAddress));
            email.To.Add(new MailboxAddress(mailObj.To ?? mailObj.To, mailObj.To));
            email.Subject = mailObj.Subject ?? string.Empty;
            email.Body = new TextPart(MimeKit.Text.TextFormat.Html)
            {
                Text = mailObj.Body ?? string.Empty
            };

            try
            {
                Console.WriteLine($"Sending email from {fromAddress} to {mailObj.To}, via {host}:{port}");
                using var smtp = new SmtpClient();
                // Choose proper TLS mode based on port/common SMTP conventions
                SecureSocketOptions socketOptions;
                if (port == 465)
                {
                    socketOptions = SecureSocketOptions.SslOnConnect;
                }
                else if (port == 587)
                {
                    socketOptions = SecureSocketOptions.StartTls;
                }
                else
                {
                    socketOptions = enableSSL ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.Auto;
                }

                await smtp.ConnectAsync(host, port, socketOptions);
                await smtp.AuthenticateAsync(fromAddress, password);
                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);
                Console.WriteLine("Email sent successfully");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending email: {ex.Message}");
                return false;
            }
        }
    }
}
