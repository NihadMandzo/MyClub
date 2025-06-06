using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class CartResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; }
        public List<CartItemResponse> Items { get; set; } = new List<CartItemResponse>();
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public decimal TotalAmount { get; set; }
    }
} 