using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Services.Database
{
    public class Category
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;
        
        public int? ParentCategoryId { get; set; }
        public virtual Category ParentCategory { get; set; }
        
        public virtual ICollection<Category> SubCategories { get; set; } = new List<Category>();
        
        // Change from direct Products collection to ProductCategories
        public virtual ICollection<ProductCategory> ProductCategories { get; set; } = new List<ProductCategory>();
        
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
} 