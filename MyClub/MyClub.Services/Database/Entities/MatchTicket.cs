using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class MatchTicket
    {
        [Key]
        public int Id { get; set; }

        [Required(ErrorMessage = "Released quantity is required")]
        [Range(0, 100, ErrorMessage = "Released quantity must be between 0 and 100")]
        public int ReleasedQuantity { get; set; }

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

        public int UsedQuantity => ReleasedQuantity - AvailableQuantity;

        public int AvailableQuantity { get; set; }
    }
} 