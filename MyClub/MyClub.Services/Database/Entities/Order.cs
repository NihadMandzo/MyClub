using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public enum OrderStatus
    {
        Pending,
        Processing,
        Shipped,
        Delivered,
        Cancelled,
        Refunded
    }
    
    public class Order
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string OrderNumber { get; set; } = string.Empty;
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual User User { get; set; }

        public Guid PaymentId { get; set; }

        [ForeignKey("PaymentId")]
        public virtual Payment Payment { get; set; }

        [Required]
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;
        
        public string  Status { get; set; } = OrderStatus.Pending.ToString();
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }
        
        public int? ShippingDetailsId { get; set; }
        
        [ForeignKey("ShippingDetailsId")]
        public virtual ShippingDetails ShippingDetails { get; set; }
        
        [MaxLength(100)]
        public string PaymentMethod { get; set; } = string.Empty;
        
        public DateTime? ShippedDate { get; set; }
        
        public DateTime? DeliveredDate { get; set; }
        
        [MaxLength(1000)]
        public string Notes { get; set; } = string.Empty;
        
        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
} 