using MyClub.Model.Responses;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class OrderStateUpdateRequest
    {
        [Required]
        public OrderStatus NewStatus { get; set; }
        
        public string Notes { get; set; }
    }
} 