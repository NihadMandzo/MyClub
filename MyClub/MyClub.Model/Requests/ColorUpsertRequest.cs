using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class ColorUpsertRequest
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [StringLength(7)]
        public string HexCode { get; set; } = string.Empty;
        
        public bool IsActive { get; set; } = true;
    }
} 