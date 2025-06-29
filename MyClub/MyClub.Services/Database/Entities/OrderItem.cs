using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class OrderItem
    {
        [Key]
        public int Id { get; set; }
        
        public int OrderId { get; set; }
        
        [ForeignKey("OrderId")]
        public virtual Order Order { get; set; }
        
        public int ProductSizeId { get; set; }
        
        [ForeignKey("ProductSizeId")]
        public virtual ProductSize ProductSize { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; }
        
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }
        
        [NotMapped]
        public decimal Subtotal => Quantity * UnitPrice;
    }
} 