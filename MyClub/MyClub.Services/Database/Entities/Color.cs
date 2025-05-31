using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class Color
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }
        
        [MaxLength(7)]
        public string HexCode { get; set; }
        
        // Navigation collections
        public virtual ICollection<Product> Products { get; set; }
    }
} 