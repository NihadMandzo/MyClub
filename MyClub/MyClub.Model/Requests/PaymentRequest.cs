using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class PaymentRequest
    {
        [Required(ErrorMessage = "Payment method is required")]
        [RegularExpression("^(Stripe|PayPal)$", ErrorMessage = "Payment method must be either 'Stripe' or 'PayPal'")]
        public string Type { get; set; }

        [Required(ErrorMessage = "Amount is required")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
        public decimal Amount { get; set; }
        public string? PaymentMethod { get; set; }

        public string? ReturnUrl { get; set; } // For PayPal return URL
        public string? CancelUrl { get; set; } // For PayPal cancel URL
    }
} 