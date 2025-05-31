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
        public string Code { get; set; }  // A1, A2, B1, B2, B3, etc.
        
        public int Capacity { get; set; }
        
        // Stadium Side relationship
        public int StadiumSideId { get; set; }
        
        [ForeignKey("StadiumSideId")]
        public virtual StadiumSide StadiumSide { get; set; }
        
        // Navigation properties
        public virtual ICollection<MatchTicket> MatchTickets { get; set; }
    }
} 