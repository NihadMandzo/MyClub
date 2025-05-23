using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class ProductImage
    {
        // Composite key is configured in DbContext
        public int ProductId { get; set; }
        public int ImageId { get; set; }
        
        [ForeignKey("ProductId")]
        public virtual Product Product { get; set; }
        
        [ForeignKey("ImageId")]
        public virtual Asset Image { get; set; }
    }
} 