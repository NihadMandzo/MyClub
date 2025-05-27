using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class SizeUpsertRequest
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;
        

    }
} 