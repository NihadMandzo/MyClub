using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class ProductSize
    {
        [Key]
        public int Id { get; set; }
        
        public int ProductId { get; set; }
        public virtual Product Product { get; set; }
        
        public int SizeId { get; set; }
        public virtual Size Size { get; set; }
        
        public int Quantity { get; set; }
    }
} 