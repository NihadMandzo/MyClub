using System;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class PlayerInsertRequest
    {
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
        public int Number { get; set; } 
        public DateTime DateOfBirth { get; set; }
        public int PositionId { get; set; } 
    public IFormFile? ImageUrl { get; set; } 
        public int Height { get; set; } 
        public int Weight { get; set; } 
    public string? Biography { get; set; } 
        public int CountryId { get; set; } 
    // Accept alternative form field name from clients
    public int? NationalityId { get; set; }
    }
}