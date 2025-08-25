using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;
using System.Runtime.Serialization;

namespace MyClub.Model.Requests
{
    public class ProductUpsertRequest
    {
        [Required(ErrorMessage = "Naziv je obavezan")]
        [MaxLength(100, ErrorMessage = "Naziv ne može biti duži od 100 karaktera")]
        public string Name { get; set; } = string.Empty;
        [Required(ErrorMessage = "Opis je obavezan")]
        [MaxLength(500, ErrorMessage = "Opis ne može biti duži od 500 karaktera")]
        public string Description { get; set; } = string.Empty;

        [MaxLength(50, ErrorMessage = "Barkod ne može biti duži od 50 karaktera")]
        public string BarCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "Cijena je obavezna")]
        [Range(0.01, 10000, ErrorMessage = "Cijena mora biti veća od 0 i manja od 10,000")]
        public decimal Price { get; set; } = 0;


        [Required(ErrorMessage = "Boja je obavezna")]
        public int ColorId { get; set; } = 0;

        [Required(ErrorMessage = "Kategorija je obavezna")]
        public int CategoryId { get; set; } = 0;
        
        public bool IsActive { get; set; } = true;
        
        // For handling image uploads
        [Required(ErrorMessage = "Slike su obavezne")]
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
        [Range(0, 10000, ErrorMessage = "Količina mora biti između 0 i 10,000")]
        public int Quantity { get; set; }
    }
} 