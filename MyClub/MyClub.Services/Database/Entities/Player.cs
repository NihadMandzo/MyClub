using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore.Internal;

namespace MyClub.Services.Database
{
    public class Player
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;
        
        [Required]
        public int Number { get; set; }
        
        public int PositionId { get; set; }
        [ForeignKey("PositionId")]
    public Position Position { get; set; } = null!;
        public DateTime? DateOfBirth { get; set; }
        
    public int CountryId { get; set; }
        [ForeignKey("CountryId")]
    public virtual Country Country { get; set; } = null!;
        
        public int? Height { get; set; }
        
        public int? Weight { get; set; }
        
    public string? Biography { get; set; }
        
        // Club relationship
        public int ClubId { get; set; }
        
        [ForeignKey("ClubId")]
    public virtual Club Club { get; set; } = null!;
        
        // Image relationship
        public int? ImageId { get; set; }
        
        [ForeignKey("ImageId")]
    public virtual Asset? Image { get; set; }
        
    public virtual string FullName 
        {
            get { return $"{FirstName} {LastName}"; }
        }
    }
} 