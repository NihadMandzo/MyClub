using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace MyClub.Services.Database
{
    public class Country
    {
        [Key]
        public int Id { get; set; }
        
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(5)]
        public string Code { get; set; } = string.Empty;
        
        public virtual ICollection<City> Cities { get; set; } = new List<City>();
        public virtual ICollection<ShippingDetails> ShippingDetails { get; set; } = new List<ShippingDetails>();
    }
}
