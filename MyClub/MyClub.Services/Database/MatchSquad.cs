using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class MatchSquad
    {
        [Key]
        public int Id { get; set; }
        
        public bool IsStarting { get; set; } = false;
        
        [MaxLength(50)]
        public string Position { get; set; }
        
        // Match relationship
        public int MatchId { get; set; }
        
        [ForeignKey("MatchId")]
        public virtual Match Match { get; set; }
        
        // Player relationship
        public int PlayerId { get; set; }
        
        [ForeignKey("PlayerId")]
        public virtual Player Player { get; set; }
    }
} 