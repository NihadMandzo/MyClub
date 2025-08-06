using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class StadiumSectorUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Code { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Capacity { get; set; }
        
        [Required]
        public int StadiumSideId { get; set; }
    }
}
