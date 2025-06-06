using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class CartItemUpsertRequest
    {
        [Required(ErrorMessage = "Product size is required")]
        public int ProductSizeId { get; set; }
        
        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; } = 1;
    }
} 