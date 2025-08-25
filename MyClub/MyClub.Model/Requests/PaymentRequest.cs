using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class PaymentRequest
    {
        [Required(ErrorMessage = "Metoda plaćanja je obavezna")]
        [RegularExpression("^(Stripe|PayPal)$", ErrorMessage = "Metoda plaćanja mora biti 'Stripe' ili 'PayPal'")]
        public string Type { get; set; }

        [Required(ErrorMessage = "Iznos je obavezan")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Iznos mora biti veći od 0")]
        public decimal Amount { get; set; }
        public string? PaymentMethod { get; set; }

        public string? ReturnUrl { get; set; } // For PayPal return URL
        public string? CancelUrl { get; set; } // For PayPal cancel URL
    }
} 