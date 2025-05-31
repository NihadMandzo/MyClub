using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class StadiumSide
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }  // North, South, East, West
        
        
        // Navigation properties
        public virtual ICollection<StadiumSector> Sectors { get; set; }
    }
} 