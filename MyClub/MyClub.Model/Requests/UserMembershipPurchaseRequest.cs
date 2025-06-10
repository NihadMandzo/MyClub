using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class UserMembershipPurchaseRequest
    {
        [Required]
        public int MembershipCardId { get; set; }
        
        public bool PhysicalCardRequested { get; set; } = false;
        
        // Address information required only if physical card is requested
        [MaxLength(100)]
        public string ShippingAddress { get; set; }
        
        [MaxLength(50)]
        public string ShippingCity { get; set; }
        
        [MaxLength(20)]
        public string ShippingPostalCode { get; set; }
        
        [MaxLength(50)]
        public string ShippingCountry { get; set; }
        
        // Payment information
        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal PaymentAmount { get; set; }
    }
} 