using System;

namespace MyClub.Model.Responses
{
    public class CartItemResponse
    {
        public int Id { get; set; }
        public int CartId { get; set; }
        public int ProductSizeId { get; set; }
        public string ProductName { get; set; }
        public string SizeName { get; set; }
        public decimal Price { get; set; }
        public string ImageUrl { get; set; }
        public int Quantity { get; set; }
        public DateTime AddedAt { get; set; }
        public decimal Subtotal { get; set; }
    }
} 