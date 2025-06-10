using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class MembershipCard
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int Year { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        public string Description { get; set; }
        
        public int TotalMembers { get; set; } = 0;
        
        [Required]
        public int TargetMembers { get; set; } = 0;
        
        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        
        [Required]
        public DateTime StartDate { get; set; }
        
        [Required]
        public DateTime EndDate { get; set; } = new DateTime(DateTime.Now.Year, 12, 31);
        
        public string Benefits { get; set; }
        
        // Image relationship
        public int? ImageId { get; set; }
        
        [ForeignKey("ImageId")]
        public virtual Asset Image { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        // Navigation collections
        public virtual ICollection<UserMembership> UserMemberships { get; set; } = new List<UserMembership>();
    }
} 