using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class MatchTicket
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int TotalQuantity { get; set; }
        
        [Required]
        public int AvailableQuantity { get; set; }
        
        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        
        // Match relationship
        public int MatchId { get; set; }
        
        [ForeignKey("MatchId")]
        public virtual Match Match { get; set; }
        
        // Stadium Sector relationship
        public int StadiumSectorId { get; set; }
        
        [ForeignKey("StadiumSectorId")]
        public virtual StadiumSector StadiumSector { get; set; }
        
        // Navigation collections
        public virtual ICollection<UserTicket> UserTickets { get; set; }
    }
} 