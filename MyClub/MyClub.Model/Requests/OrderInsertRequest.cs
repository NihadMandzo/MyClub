using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using MyClub.Model.Requests;

namespace MyClub.Model.Requests
{
    public class OrderInsertRequest : PaymentRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public ShippingRequest Shipping { get; set; }

        public string? Notes { get; set; }
        
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

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }

    }
} 