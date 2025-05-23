using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class StadiumSector
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }  // A1, A2, B1, B2, B3, etc.
        
        [Required]
        [MaxLength(50)]
        public string FullName { get; set; }  // South A1, South A2, etc.
        
        public int Capacity { get; set; }
        
        [MaxLength(255)]
        public string Description { get; set; }
        
        // Stadium Side relationship
        public int StadiumSideId { get; set; }
        
        [ForeignKey("StadiumSideId")]
        public virtual StadiumSide StadiumSide { get; set; }
        
        // Navigation properties
        public virtual ICollection<MatchTicket> MatchTickets { get; set; }
    }
} 