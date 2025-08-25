using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class CartItemUpsertRequest
    {
        [Required(ErrorMessage = "Proizvod je obavezan")]
        public int ProductSizeId { get; set; }
        
        [Required(ErrorMessage = "Količina je obavezna")]
        [Range(1, int.MaxValue, ErrorMessage = "Količina mora biti najmanje 1")]
        public int Quantity { get; set; } = 1;
    }
} 