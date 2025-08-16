using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class PositionUpsertRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        public bool IsPlayer { get; set; } = true;
    }
} 