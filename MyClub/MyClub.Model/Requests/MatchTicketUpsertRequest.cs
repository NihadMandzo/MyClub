using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchTicketUpsertRequest
    {
        
        [Required(ErrorMessage = "Released quantity is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Released quantity cannot be negative")]
        public int ReleasedQuantity { get; set; }
        
        [Required(ErrorMessage = "Price is required")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
        public decimal Price { get; set; }
        
        [Required(ErrorMessage = "Stadium sector is required")]
        public int StadiumSectorId { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
} 