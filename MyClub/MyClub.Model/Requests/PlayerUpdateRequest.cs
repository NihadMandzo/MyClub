using System;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class PlayerUpdateRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int Number { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string Position { get; set; }
        public int? Height { get; set; }
        public int? Weight { get; set; }
        public string Biography { get; set; }
        public IFormFile ImageUrl { get; set; }
        
    }
}