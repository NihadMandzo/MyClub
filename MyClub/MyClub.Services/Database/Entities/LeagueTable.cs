using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class LeagueTable
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string ClubName { get; set; }
        
        public int? LogoImageId { get; set; }
        
        [ForeignKey("LogoImageId")]
        public virtual Asset LogoImage { get; set; }
        
        public int MatchesPlayed { get; set; } = 0;
        
        public int Wins { get; set; } = 0;
        
        public int Draws { get; set; } = 0;
        
        public int Losses { get; set; } = 0;
        
        public int GoalsFor { get; set; } = 0;
        
        public int GoalsAgainst { get; set; } = 0;
        
        public int Points { get; set; } = 0;
        
        [NotMapped]
        public int GoalDifference => GoalsFor - GoalsAgainst;
    }
} 