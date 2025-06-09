using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class TicketPurchaseRequest
    {
        [Required(ErrorMessage = "Match ticket ID is required")]
        public int MatchTicketId { get; set; }
        
        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10")]
        public int Quantity { get; set; }
        
        [Required(ErrorMessage = "User ID is required")]
        public int UserId { get; set; }
    }
} 