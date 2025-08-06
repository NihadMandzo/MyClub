using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class CountryUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
    }
}
