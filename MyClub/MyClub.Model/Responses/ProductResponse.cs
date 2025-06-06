using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class ProductResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string BarCode { get; set; }
        public decimal Price { get; set; }
        public int? ColorId { get; set; }
        public string ColorName { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal? Rating { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; }
        public string PrimaryImageUrl { get; set; }
    }
} 