using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchTicketUpsertRequest
    {
        [Required(ErrorMessage = "Total quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Total quantity must be at least 1")]
        public int TotalQuantity { get; set; }
        
        [Required(ErrorMessage = "Available quantity is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Available quantity cannot be negative")]
        public int AvailableQuantity { get; set; }
        
        [Required(ErrorMessage = "Price is required")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
        public decimal Price { get; set; }
        
        [Required(ErrorMessage = "Stadium sector is required")]
        public int StadiumSectorId { get; set; }
    }
} 