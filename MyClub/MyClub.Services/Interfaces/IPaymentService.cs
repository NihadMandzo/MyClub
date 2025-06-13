using MyClub.Model.Requests;

namespace MyClub.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<string> CreateStripePaymentAsync(PaymentRequest request);
        Task<string> CreatePayPalPaymentAsync(PaymentRequest request);
        Task HandleWebhookAsync(string provider, object payload);
        Task<Payment> GetPaymentByIdAsync(Guid paymentId);
        Task UpdatePaymentStatusAsync(Guid paymentId, string status);
    }
} 