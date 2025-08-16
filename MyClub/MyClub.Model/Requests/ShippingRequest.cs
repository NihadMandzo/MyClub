using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class ShippingRequest    
    {
        [MaxLength(100)]
        public string ShippingAddress { get; set; }
        
        [MaxLength(50)]
        public int CityId { get; set; }
        
        [MaxLength(20)]
        public string ShippingPostalCode { get; set; }
        }
}