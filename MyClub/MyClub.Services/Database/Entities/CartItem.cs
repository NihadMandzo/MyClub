using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class CartItem
    {
        [Key]
        public int Id { get; set; }
        
        public int CartId { get; set; }
        
        [ForeignKey("CartId")]
        public virtual Cart Cart { get; set; }
        
        public int ProductSizeId { get; set; }
        
        [ForeignKey("ProductSizeId")]
        public virtual ProductSize ProductSize { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; } = 1;
        
        public DateTime AddedAt { get; set; } = DateTime.UtcNow;
        
        [NotMapped]
        public decimal Subtotal => Quantity * (ProductSize?.Product?.Price ?? 0);
    }
} 