using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class TicketPurchaseRequest : PaymentRequest
    {
        [Required(ErrorMessage = "Match ticket ID is required")]
        public int MatchTicketId { get; set; }

    }
} 