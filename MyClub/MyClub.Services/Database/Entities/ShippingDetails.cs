using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace MyClub.Services.Database
{
    public class ShippingDetails
    {
        [Key]
        public int Id { get; set; }
        
        [MaxLength(100)]
        public string ShippingAddress { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string ShippingCity { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string ShippingPostalCode { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string ShippingCountry { get; set; } = string.Empty;
        
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        public virtual ICollection<UserMembership> UserMemberships { get; set; } = new List<UserMembership>();
    }
} 