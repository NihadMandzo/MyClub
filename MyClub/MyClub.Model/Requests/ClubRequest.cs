using System;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class ClubRequest
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public IFormFile LogoImage { get; set; } // Assuming IFromFile is a custom interface for file uploads
    }
}