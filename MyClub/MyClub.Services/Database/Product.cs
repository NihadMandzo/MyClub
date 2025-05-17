using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Product
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;
        
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        
        [MaxLength(50)]
        public string SKU { get; set; } = string.Empty;
        
        public int StockQuantity { get; set; } = 0;
        
        // Product Type relationship
        public int? ProductTypeId { get; set; }
        
        [ForeignKey("ProductTypeId")]
        public virtual ProductType ProductType { get; set; }
        
        // Unit of Measure relationship
        public int? UnitOfMeasureId { get; set; }
        
        [ForeignKey("UnitOfMeasureId")]
        public virtual UnitOfMeasure UnitOfMeasure { get; set; }
        
        // Weight/dimensions
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Weight { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Length { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Width { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Height { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        [MaxLength(50)]
        public string Brand { get; set; } = string.Empty;
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal? Rating { get; set; }
        
        public virtual ICollection<Asset> Assets { get; set; } = new List<Asset>();
        public virtual ICollection<ProductReview> Reviews { get; set; } = new List<ProductReview>();
        public virtual ICollection<ProductCategory> ProductCategories { get; set; } = new List<ProductCategory>();
    }
}