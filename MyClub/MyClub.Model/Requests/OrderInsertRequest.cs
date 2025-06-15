using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class OrderInsertRequest
    {
        [Required]
        public string ShippingAddress { get; set; }
        
        [Required]
        public string ShippingCity { get; set; }
        
        [Required]
        public string ShippingPostalCode { get; set; }
        
        [Required]
        public string ShippingCountry { get; set; }

        [Required]
        public string PaymentMethod { get; set; }

        [Required]
        public decimal TotalAmount { get; set; }

        public string Notes { get; set; }

        
        [Required]
        public List<OrderItemInsertRequest> Items { get; set; }
    }

    public class OrderItemInsertRequest
    {
        [Required]
        public int ProductSizeId { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; }
    }
} 