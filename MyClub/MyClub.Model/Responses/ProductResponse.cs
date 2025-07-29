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
        public ColorResponse Color { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal? Rating { get; set; }
        public CategoryResponse Category { get; set; }
        public AssetResponse PrimaryImageUrl { get; set; }

        public List<AssetResponse> ImageUrls { get; set; } = new List<AssetResponse>();
        public List<ProductSizeResponse> Sizes { get; set; } = new List<ProductSizeResponse>();
    }
} 