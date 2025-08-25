using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchTicketUpsertRequest
    {

        [Required(ErrorMessage = "Količina je obaveznad")]
        [Range(0, int.MaxValue, ErrorMessage = "Količina ne može biti negativna")]
        public int ReleasedQuantity { get; set; }
        
        [Required(ErrorMessage = "Cijena je obavezna")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Cijena mora biti veća od 0")]
        public decimal Price { get; set; }

        [Required(ErrorMessage = "Sektor stadiona je obavezan")]
        public int StadiumSectorId { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
} 