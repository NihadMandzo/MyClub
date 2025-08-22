using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class UserMembership
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        public int MembershipCardId { get; set; }

        [ForeignKey("MembershipCardId")]
        public virtual MembershipCard MembershipCard { get; set; }
        
        public int PaymentId { get; set; }

        [ForeignKey("PaymentId")]
        public virtual Payment? Payment { get; set; }
        public DateTime JoinDate { get; set; } = DateTime.UtcNow;
        
        // For friend purchase
        [MaxLength(50)]
        public string? RecipientFirstName { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? RecipientLastName { get; set; } = string.Empty;
        
        // For physical card delivery
        public bool PhysicalCardRequested { get; set; } = false;
        
        // Address information for card delivery
        public int? ShippingDetailsId { get; set; }
        
        [ForeignKey("ShippingDetailsId")]
        public virtual ShippingDetails? ShippingDetails { get; set; }
        
        // Delivery status
        public bool IsShipped { get; set; } = false;
        
        public DateTime? ShippedDate { get; set; }
        
        public bool IsPaid { get; set; } = false;
        
        public DateTime? PaymentDate { get; set; }
    }
} 