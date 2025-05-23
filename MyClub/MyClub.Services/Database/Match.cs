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
        public bool IsHomeMatch { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string OpponentName { get; set; }
        
        
        public int? HomeGoals { get; set; }
        
        public int? AwayGoals { get; set; }
        
        [MaxLength(50)]
        public string Status { get; set; } = "Scheduled";

        // Club relationship
        public int ClubId { get; set; }
        
        [ForeignKey("ClubId")]
        public virtual Club Club { get; set; }
        
        // Navigation collections
        public virtual ICollection<MatchComment> Comments { get; set; }
        public virtual ICollection<MatchSquad> Squad { get; set; }
        public virtual ICollection<MatchTicket> Tickets { get; set; }
    }
} 