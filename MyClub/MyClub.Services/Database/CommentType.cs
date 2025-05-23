using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class CommentType
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }
        
        [MaxLength(255)]
        public string Description { get; set; }
        
        // For example: Goal, Card, Substitution, General, Injury, etc.
        public string Icon { get; set; }
        
        // Navigation properties
        public virtual ICollection<MatchComment> MatchComments { get; set; }
    }
} 