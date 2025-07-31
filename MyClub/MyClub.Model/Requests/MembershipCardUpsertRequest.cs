using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class MembershipCardUpsertRequest
    {
        [Required]
        public int Year { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }
        
        public string Description { get; set; }
        
        [Required]
        public int TargetMembers { get; set; }
        
        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal Price { get; set; }
        
        [Required]
        public DateTime StartDate { get; set; }
        
        public DateTime? EndDate { get; set; }
        
        public string Benefits { get; set; }
        
        public IFormFile Image { get; set; }

        public bool? KeepImage { get; set; } = false;
        
        public bool IsActive { get; set; } = true;
    }
} 