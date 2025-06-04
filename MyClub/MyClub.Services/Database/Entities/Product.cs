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
        
        [MaxLength(50)]
        public string BarCode { get; set; } = string.Empty;
        
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        
        public int ColorId { get; set; }
        
        [ForeignKey("ColorId")]
        public virtual Color Color { get; set; }
        
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal? Rating { get; set; }

        public int CategoryId { get; set; }
        [ForeignKey("CategoryId")]    
        public virtual Category Category { get; set; }
        public virtual ICollection<ProductAsset> ProductAssets { get; set; } = new List<ProductAsset>();

        public virtual ICollection<ProductSize> ProductSizes { get; set; } = new List<ProductSize>();
    }
}