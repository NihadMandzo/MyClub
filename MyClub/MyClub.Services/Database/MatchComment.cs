using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class MatchComment
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string Description { get; set; }
        
        public int? Minute { get; set; }
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Match relationship
        public int MatchId { get; set; }
        
        [ForeignKey("MatchId")]
        public virtual Match Match { get; set; }
        
        // CommentType relationship
        public int CommentTypeId { get; set; }
        
        [ForeignKey("CommentTypeId")]
        public virtual CommentType CommentType { get; set; }
        
        // Optional Player reference (for player-specific events like goals, cards)
        public int? PlayerId { get; set; }
        
        [ForeignKey("PlayerId")]
        public virtual Player Player { get; set; }
    }
} 