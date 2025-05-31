using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class ProductAsset
    {
        public int ProductId { get; set; }
                
        [ForeignKey("ProductId")]
        public virtual Product Product { get; set; }
        public int AssetId { get; set; }
        
        [ForeignKey("AssetId")]
        public virtual Asset Asset { get; set; }
    }
} 