using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class News
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(200)]
        public string Title { get; set; }
        
        [Required]
        public string Content { get; set; }
        
        [MaxLength(255)]
        public string? VideoURL { get; set; }
        
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        
        // User relationship
        public int UserId { get; set; }
        public virtual User User { get; set; }
        
        // Navigation collections
        public virtual ICollection<Comment> Comments { get; set; } = new List<Comment>();
        public virtual ICollection<NewsAsset> NewsAssets { get; set; } = new List<NewsAsset>();
    }
} 