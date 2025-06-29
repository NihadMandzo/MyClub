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
        public string ShippingAddress { get; set; }
        
        [Required]
        public string ShippingCity { get; set; }
        
        [Required]
        public string ShippingPostalCode { get; set; }
        
        [Required]
        public string ShippingCountry { get; set; }

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

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }
    }
} 