using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Cart
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        
        public virtual ICollection<CartItem> Items { get; set; } = new List<CartItem>();
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        [NotMapped]
        public decimal TotalAmount => CalculateTotalAmount();
        
        private decimal CalculateTotalAmount()
        {
            decimal total = 0;
            if (Items != null)
            {
                foreach (var item in Items)
                {
                    total += item.Quantity * (item?.Subtotal ?? 0);
                }
            }
            return total;
        }
    }
} 