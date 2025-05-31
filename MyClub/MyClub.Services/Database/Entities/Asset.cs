using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Asset
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(255)]
        public string Url { get; set; } = string.Empty;
        
        public virtual ICollection<ProductAsset> ProductAssets { get; set; } = new List<ProductAsset>();
        public virtual ICollection<NewsAsset> NewsAssets { get; set; } = new List<NewsAsset>();
    
    }
} 