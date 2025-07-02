using MyClub.Model.Requests;
using MyClub.Model.Responses;

namespace MyClub.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentResponse> CreateStripePaymentAsync(PaymentRequest request);
        Task<string> CreatePayPalPaymentAsync(PaymentRequest request);
        Task<bool> ConfirmStripePayment(string transactionId);
    }
} 