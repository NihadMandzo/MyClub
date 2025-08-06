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
        
        public int? CityId { get; set; }
        
        [ForeignKey(nameof(CityId))]
        public virtual City? City { get; set; }
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        public virtual ICollection<UserMembership> UserMemberships { get; set; } = new List<UserMembership>();
    }
} 