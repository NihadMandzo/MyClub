using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;
using System.Runtime.Serialization;

namespace MyClub.Model.Requests
{
    public class ProductUpsertRequest
    {
        [Required(ErrorMessage = "Name is required")]
        [MaxLength(100, ErrorMessage = "Name cannot exceed 100 characters")]
        public string Name { get; set; } = string.Empty;
        [Required(ErrorMessage = "Description is required")]
        [MaxLength(500, ErrorMessage = "Description cannot exceed 500 characters")]
        public string Description { get; set; }
        
        [MaxLength(50, ErrorMessage = "Barcode cannot exceed 50 characters")]
        public string BarCode { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Price is required")]
        [Range(0.01, 10000, ErrorMessage = "Price must be greater than 0 and less than 10,000")]
        public decimal Price { get; set; } = 0;
        
        
        [Required(ErrorMessage = "Color is required")]
        public int ColorId { get; set; } = 0;
        
        [Required(ErrorMessage = "Category is required")]
        public int CategoryId { get; set; } = 0;
        
        public bool IsActive { get; set; } = true;
        
        // For handling image uploads
        [Required(ErrorMessage = "Images are required")]
        public List<IFormFile> Images { get; set; } = new List<IFormFile>();
        
        // For tracking existing images when updating
        public List<int> ImagesToKeep { get; set; } = new List<int>();
        
        // For product sizes with quantities
        
        public List<ProductSizeRequest> ProductSizes { get; set; } = new List<ProductSizeRequest>();
        
        // Helper properties for form submission
        [IgnoreDataMember]
        public List<int> SizeIds { get; set; } = new List<int>();
        
        [IgnoreDataMember]
        public List<int> Quantities { get; set; } = new List<int>();
    }

    public class ProductSizeRequest
    {
        [Required]
        public int SizeId { get; set; }
        
        [Required]
        [Range(0, 10000, ErrorMessage = "Quantity must be between 0 and 10,000")]
        public int Quantity { get; set; }
    }
} 