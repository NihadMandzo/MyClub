using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class NewsComment
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string Content { get; set; }
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // News relationship
        public int NewsId { get; set; }
        public virtual News News { get; set; }
        
        // User relationship
        public int UserId { get; set; }
        public virtual User User { get; set; }
    }
} 