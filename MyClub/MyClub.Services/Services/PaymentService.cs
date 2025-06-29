
using MyClub.Model.Requests;
using MyClub.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database;
using Microsoft.Extensions.Logging;
using MyClub.Model.Responses;
using Stripe;
using Microsoft.Extensions.Configuration;

namespace MyClub.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly MyClubContext _context;
        private readonly ILogger<PaymentService> _logger;
        private readonly IConfiguration _configuration;
        public PaymentService(MyClubContext context, ILogger<PaymentService> logger, IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _configuration = configuration;
            StripeConfiguration.ApiKey = _configuration.GetSection("Stripe:SecretKey").Value;
        }

        public async Task<PaymentResponse> CreateStripePaymentAsync(PaymentRequest request)
        {

            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(request.Amount * 100),
                Currency = "BAM",
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                },
            };
            var service = new PaymentIntentService();
            PaymentIntent paymentIntent = service.Create(options);

            return new PaymentResponse
            {
                clientSecret = paymentIntent.ClientSecret,
                transactionId = paymentIntent.Id
            };
        }

        public async Task<string> CreatePayPalPaymentAsync(PaymentRequest request)
        {
            return null;
        }

        public async Task<bool> ConfirmStripePayment(Guid transactionId)
        {
            var paymentIntent = await _context.Payments.FirstOrDefaultAsync(x => x.TransactionId == transactionId);
            if (paymentIntent == null)
            {
                throw new KeyNotFoundException($"Payment with ID {transactionId} not found");
            }
            paymentIntent.Status = "Completed";
            await _context.SaveChangesAsync();
            return true;
        }
    }
}