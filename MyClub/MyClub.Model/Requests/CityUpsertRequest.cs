using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;
        
        [Required]
        public int CountryId { get; set; }
    }
}
