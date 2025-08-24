using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PayPalTestController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PayPalTestController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpGet("check/{orderId}")]
        public async Task<IActionResult> CheckOrderStatus(string orderId)
        {
            try
            {
                var configuration = HttpContext.RequestServices.GetRequiredService<IConfiguration>();
                var client = PayPalTestExtensions.CreatePayPalClient(configuration);
                var request = new PayPalCheckoutSdk.Orders.OrdersGetRequest(orderId);
                var response = await client.Execute(request);
                var order = response.Result<PayPalCheckoutSdk.Orders.Order>();

                return Ok(new
                {
                    orderId = order.Id,
                    status = order.Status,
                });
            }
            catch (Exception ex)
            {
                return BadRequest($"Error checking order: {ex.Message}");
            }
        }
    }

    public class PayPalTestRequest
    {
        public decimal Amount { get; set; }
    }

    public class PayPalCaptureRequest
    {
        public string OrderId { get; set; } = string.Empty;
    }

    // Add status check endpoint
    public static class PayPalTestExtensions
    {
        public static PayPalCheckoutSdk.Core.PayPalHttpClient CreatePayPalClient(IConfiguration configuration)
        {
            var clientId = configuration["PayPal:ClientId"];
            var secret = configuration["PayPal:Secret"];
            var env = configuration["PayPal:Environment"] ?? "Sandbox";

            PayPalCheckoutSdk.Core.PayPalEnvironment environment = string.Equals(env, "Live", StringComparison.OrdinalIgnoreCase)
                ? new PayPalCheckoutSdk.Core.LiveEnvironment(clientId, secret)
                : new PayPalCheckoutSdk.Core.SandboxEnvironment(clientId, secret);

            return new PayPalCheckoutSdk.Core.PayPalHttpClient(environment);
        }
    }
}
