using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchUpsertRequest
    {
        [Required(ErrorMessage = "Match date is required")]
        public DateTime MatchDate { get; set; }
        
        [Required(ErrorMessage = "Home match flag is required")]
        public bool IsHomeMatch { get; set; }
        
        [Required(ErrorMessage = "Opponent name is required")]
        [MaxLength(100, ErrorMessage = "Opponent name cannot exceed 100 characters")]
        public string OpponentName { get; set; }
        
        public int? HomeGoals { get; set; }
        
        public int? AwayGoals { get; set; }
        
        [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
        public string Status { get; set; } = "Scheduled";
        
        [Required(ErrorMessage = "Club is required")]
        public int ClubId { get; set; }
        
        public List<MatchTicketUpsertRequest> Tickets { get; set; } = new List<MatchTicketUpsertRequest>();
    }
} 