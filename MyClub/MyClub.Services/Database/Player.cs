using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Player
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string LastName { get; set; }
        
        [Required]
        public int Number { get; set; }
        
        [MaxLength(50)]
        public string Position { get; set; }
        
        public DateTime? DateOfBirth { get; set; }
        
        [MaxLength(100)]
        public string Nationality { get; set; }
        
        public int? Height { get; set; }
        
        public int? Weight { get; set; }
        
        public string Biography { get; set; }
        
        // Club relationship
        public int ClubId { get; set; }
        
        [ForeignKey("ClubId")]
        public virtual Club Club { get; set; }
        
        // Image relationship
        public int? ImageId { get; set; }
        
        [ForeignKey("ImageId")]
        public virtual Asset Image { get; set; }
        
        // Navigation collections
        public virtual ICollection<MatchSquad> MatchSquads { get; set; }
    }
} 