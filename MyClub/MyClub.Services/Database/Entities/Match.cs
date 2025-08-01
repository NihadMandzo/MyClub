using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Match
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public DateTime MatchDate { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string OpponentName { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Location { get; set; }
        
        [MaxLength(50)]
        public string Status { get; set; } = "Scheduled";
        
        [MaxLength(500)]
        public string Description { get; set; }
        
        // Club relationship
        public int ClubId { get; set; }
        
        [ForeignKey("ClubId")]
        public virtual Club Club { get; set; }

        public int HomeGoals { get; set; } = 0;
        public int AwayGoals { get; set; } = 0;
        
        // Navigation properties
        public virtual ICollection<MatchTicket> Tickets { get; set; }
    }
} 