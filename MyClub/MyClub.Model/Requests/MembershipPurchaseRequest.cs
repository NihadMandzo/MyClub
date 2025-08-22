using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MembershipPurchaseRequest : PaymentRequest
    {
        [Required]
        public int MembershipCardId { get; set; }
        
        // Gift purchase fields (optional)
        [MaxLength(50)]
        public string? RecipientFirstName { get; set; }
        
        [MaxLength(50)]
        public string? RecipientLastName { get; set; }
        
        // Physical card delivery
        public bool PhysicalCardRequested { get; set; } = false;
        
        // Shipping details (required if PhysicalCardRequested is true)
        public ShippingRequest? Shipping { get; set; }
    }
    
}
