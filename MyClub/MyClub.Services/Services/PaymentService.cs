
using MyClub.Model.Requests;
using MyClub.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database;
using Microsoft.Extensions.Logging;
using MyClub.Model.Responses;
using Stripe;
using PayPalCheckoutSdk.Core;
using PayPalCheckoutSdk.Orders;
using PayPalHttp;
using Microsoft.Extensions.Configuration;
using System.Globalization;

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
            PaymentIntent paymentIntent = await service.CreateAsync(options);

            return new PaymentResponse
            {
                clientSecret = paymentIntent.ClientSecret,
                transactionId = paymentIntent.Id
            };
        }

        public async Task<PaymentResponse> CreatePayPalPaymentAsync(PaymentRequest request)
        {
            try
            {
                var client = CreatePayPalClient();
                var currency = "EUR";

                // Provide sane defaults for Return/Cancel URLs when not sent by client (e.g., mobile deep links)
                var returnUrl = string.IsNullOrWhiteSpace(request.ReturnUrl)
                    ? (_configuration["PayPal:ReturnUrl"] ?? string.Empty)
                    : request.ReturnUrl;
                var cancelUrl = string.IsNullOrWhiteSpace(request.CancelUrl)
                    ? (_configuration["PayPal:CancelUrl"] ?? string.Empty)
                    : request.CancelUrl;

                if (currency == "EUR")
                    request.Amount = Math.Round(request.Amount / 1.95583m, 2); // Convert BAM to EUR

                _logger.LogInformation($"Creating PayPal payment for amount: {request.Amount} {currency}");
                if (string.IsNullOrWhiteSpace(returnUrl) || string.IsNullOrWhiteSpace(cancelUrl))
                {
                    _logger.LogWarning("PayPal ReturnUrl/CancelUrl not provided by client or config. Approval redirect may fail.");
                }

                var orderRequest = new OrderRequest
                {
                    CheckoutPaymentIntent = "CAPTURE",
                    ApplicationContext = new ApplicationContext
                    {
                        ReturnUrl = string.IsNullOrWhiteSpace(returnUrl) ? null : returnUrl,
                        CancelUrl = string.IsNullOrWhiteSpace(cancelUrl) ? null : cancelUrl,
                        BrandName = _configuration["PayPal:BrandName"] ?? "MyClub",
                        UserAction = "PAY_NOW"
                    },
                    PurchaseUnits = new List<PurchaseUnitRequest>
                    {
                        new PurchaseUnitRequest
                        {
                            AmountWithBreakdown = new AmountWithBreakdown
                            {
                                CurrencyCode = currency,
                                Value = request.Amount.ToString("F2", CultureInfo.InvariantCulture)
                            }
                        }
                    }
                };

                var createRequest = new OrdersCreateRequest();
                createRequest.Prefer("return=representation");
                createRequest.RequestBody(orderRequest);

                _logger.LogInformation("Sending PayPal order creation request...");
                var response = await client.Execute(createRequest);
                var result = response.Result<PayPalCheckoutSdk.Orders.Order>();

                var approvalLink = result.Links.FirstOrDefault(l =>
                    string.Equals(l.Rel, "approve", StringComparison.OrdinalIgnoreCase))?.Href;

                _logger.LogInformation($"PayPal order created successfully. Order ID: {result.Id}");

                return new PaymentResponse
                {
                    transactionId = result.Id,
                    approvalUrl = approvalLink
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create PayPal payment");
                throw new InvalidOperationException($"PayPal payment creation failed: {ex.Message}", ex);
            }
        }

        public async Task<bool> ConfirmStripePayment(string transactionId)
        {
            var paymentIntent = await _context.Payments.FirstOrDefaultAsync(x => x.TransactionId == transactionId);
            if (paymentIntent == null)
            {
                throw new KeyNotFoundException($"Payment with ID {transactionId} not found");
            }
            paymentIntent.Status = "Completed";
            paymentIntent.CompletedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        private PayPalHttpClient CreatePayPalClient()
        {
            var clientId = (_configuration["PayPal:ClientId"] ?? string.Empty).Trim();
            var secret = (_configuration["PayPal:Secret"] ?? string.Empty).Trim();
            var env = (_configuration["PayPal:Environment"] ?? "Sandbox").Trim();

            if (string.IsNullOrEmpty(clientId))
            {
                throw new InvalidOperationException("PayPal ClientId is not configured");
            }

            if (string.IsNullOrEmpty(secret))
            {
                throw new InvalidOperationException("PayPal Secret is not configured");
            }

            _logger.LogInformation($"Creating PayPal client for environment: {env}");
            _logger.LogInformation($"PayPal ClientId: {clientId.Substring(0, Math.Min(10, clientId.Length))}...");

            PayPalEnvironment environment = string.Equals(env, "Live", StringComparison.OrdinalIgnoreCase)
                ? new LiveEnvironment(clientId, secret)
                : new SandboxEnvironment(clientId, secret);

            return new PayPalHttpClient(environment);
        }

        public async Task<bool> CapturePayPalPaymentAsync(string orderId)
        {
            var client = CreatePayPalClient();

            var captureRequest = new OrdersCaptureRequest(orderId);
            captureRequest.Prefer("return=representation");
            captureRequest.RequestBody(new OrderActionRequest());

            var response = await client.Execute(captureRequest);
            var order = response.Result<PayPalCheckoutSdk.Orders.Order>();

            var completed = string.Equals(order.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase);

            // Optional: persist status in your DB
            var payment = await _context.Payments.FirstOrDefaultAsync(x => x.TransactionId == orderId);
            if (payment != null)
            {
                payment.Status = completed ? "Completed" : order.Status ?? "Failed";
                if (completed)
                    payment.CompletedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
            }

            return completed;
        }

    }
}