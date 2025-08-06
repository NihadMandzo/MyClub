using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class StadiumSideUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; }
    }
}
