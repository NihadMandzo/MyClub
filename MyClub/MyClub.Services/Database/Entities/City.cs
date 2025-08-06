using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace MyClub.Services.Database
{
    public class City
    {
        [Key]
        public int Id { get; set; }
        
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;
        
        public int CountryId { get; set; }
        
        [ForeignKey(nameof(CountryId))]
        public virtual Country Country { get; set; } = null!;
        
        public virtual ICollection<ShippingDetails> ShippingDetails { get; set; } = new List<ShippingDetails>();
    }
}
