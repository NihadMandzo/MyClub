using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class SizeUpsertRequest
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [StringLength(100)]
        public string Code { get; set; } = string.Empty;
        
        public bool IsActive { get; set; } = true;
    }
} 