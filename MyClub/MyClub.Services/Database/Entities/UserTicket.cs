using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class UserTicket
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int Quantity { get; set; }
        
        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal TotalPrice { get; set; }
        
        [Required]
        public DateTime PurchaseDate { get; set; } = DateTime.UtcNow;
        
        [MaxLength(500)]
        public string QRCode { get; set; }
        
        [MaxLength(50)]
        public string Status { get; set; } = "Valid";
        public Guid PaymentId { get; set; }

        [ForeignKey("PaymentId")]
        public virtual Payment Payment { get; set; }
        
        // User relationship
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        
        // MatchTicket relationship
        public int MatchTicketId { get; set; }
        
        [ForeignKey("MatchTicketId")]
        public virtual MatchTicket MatchTicket { get; set; }
    }
} 