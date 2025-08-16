using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore.Internal;

namespace MyClub.Services.Database
{
    public class Position
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        public bool IsPlayer { get; set; } = true;

        public virtual ICollection<Player> Players { get; set; }
    }
} 