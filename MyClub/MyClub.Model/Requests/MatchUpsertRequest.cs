using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchUpsertRequest
    {
        [Required(ErrorMessage = "Match date is required")]
        public DateTime MatchDate { get; set; }

        [Required(ErrorMessage = "Opponent name is required")]
        [MaxLength(100, ErrorMessage = "Opponent name cannot exceed 100 characters")]
        public string OpponentName { get; set; }

        [Required(ErrorMessage = "Location is required")]
        [MaxLength(100, ErrorMessage = "Location cannot exceed 100 characters")]
        public string Location { get; set; }

        [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
        public string Status { get; set; } = "Scheduled";

        [MaxLength(500, ErrorMessage = "Description cannot exceed 500 characters")]
        public string Description { get; set; }

        [Required(ErrorMessage = "Club is required")]
        public int ClubId { get; set; }
    }
} 