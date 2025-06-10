using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class UserMembershipUpsertRequest
    {
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int MembershipCardId { get; set; }
        
        public bool IsRenewal { get; set; } = false;
        
        public int? PreviousMembershipId { get; set; }
        
        [MaxLength(50)]
        public string RecipientFirstName { get; set; }
        
        [MaxLength(50)]
        public string RecipientLastName { get; set; }
        
        [EmailAddress]
        [MaxLength(100)]
        public string RecipientEmail { get; set; }
        
        public bool PhysicalCardRequested { get; set; } = false;
        
        [MaxLength(100)]
        public string ShippingAddress { get; set; }
        
        [MaxLength(50)]
        public string ShippingCity { get; set; }
        
        [MaxLength(20)]
        public string ShippingPostalCode { get; set; }
        
        [MaxLength(50)]
        public string ShippingCountry { get; set; }
        
        public bool IsShipped { get; set; } = false;
        
        public DateTime? ShippedDate { get; set; }
        
        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal PaymentAmount { get; set; }
        
        public bool IsPaid { get; set; } = false;
        
        public DateTime? PaymentDate { get; set; }
    }
} 