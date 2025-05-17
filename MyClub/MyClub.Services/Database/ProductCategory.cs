using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class ProductCategory
    {
        [Key]
        public int Id { get; set; }
        
        public int ProductId { get; set; }
        
        [ForeignKey("ProductId")]
        public virtual Product Product { get; set; }
        
        public int CategoryId { get; set; }
        
        [ForeignKey("CategoryId")]
        public virtual Category Category { get; set; }
        
        // Optional: if you want to track when the product was added to a category
        public System.DateTime DateAdded { get; set; } = System.DateTime.UtcNow;
    }
} 