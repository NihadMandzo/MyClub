using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class CountryUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(5)]
        public string Code { get; set; } = string.Empty;
    }
}
