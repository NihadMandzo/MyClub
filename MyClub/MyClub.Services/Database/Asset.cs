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
        
        [ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        
        public virtual Product Product { get; set; }
    }
} 