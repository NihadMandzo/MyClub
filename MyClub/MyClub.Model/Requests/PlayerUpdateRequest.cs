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
        public int PositionId { get; set; }
        public int? Height { get; set; }
        public int? Weight { get; set; }
        public string Biography { get; set; }
        public bool KeepPicture { get; set; }
        public IFormFile? ImageUrl { get; set; }
        public int CountryId { get; set; }
    }
}