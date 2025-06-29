using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public abstract class PaymentRequest
    {
        [Required(ErrorMessage = "Payment method is required")]
        [RegularExpression("^(Stripe|PayPal)$", ErrorMessage = "Payment method must be either 'Stripe' or 'PayPal'")]
        public string Type { get; set; }

        [Required(ErrorMessage = "Amount is required")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
        public decimal Amount { get; set; }

        public string PaymentMethod { get; set; }

    }
} 