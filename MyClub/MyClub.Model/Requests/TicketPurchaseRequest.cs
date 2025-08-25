using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class TicketPurchaseRequest : PaymentRequest
    {
        [Required(ErrorMessage = "Karta je obavezna")]
        public int MatchTicketId { get; set; }

    }
} 