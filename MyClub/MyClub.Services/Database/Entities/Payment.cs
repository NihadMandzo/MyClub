using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public class Payment
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        [StringLength(10)]
        public string Method { get; set; }

        [Required]
        [StringLength(20)]
        public string Status { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        public virtual Order? Order { get; set; }
        public virtual UserTicket? UserTicket { get; set; }
        public virtual UserMembership? UserMembership { get; set; }
    }
} 