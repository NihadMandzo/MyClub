using MyClub.Model;

namespace MyClub.Subscriber
{
    public class EmailService
    {
        public async Task<bool> SendEmail(EmailMessage email)
        {
            if (email == null)
            {
                Console.WriteLine("Email payload is null");
                return false;
            }

            if (string.IsNullOrWhiteSpace(email.To))
            {
                Console.WriteLine("Recipient email is empty");
                return false;
            }

            return await MailSender.SendEmail(email);
        }
    }
}
