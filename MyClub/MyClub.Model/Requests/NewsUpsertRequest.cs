using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class NewsUpsertRequest
    {
        [Required(ErrorMessage = "Naslov je obavezan")]
        [StringLength(200, MinimumLength = 3, ErrorMessage = "Naslov mora biti između 3 i 200 karaktera")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Sadržaj je obavezan")]
        [MinLength(10, ErrorMessage = "Sadržaj mora imati najmanje 10 karaktera")]
        public string Content { get; set; } = string.Empty;

        [Url(ErrorMessage = "Neispravan format video URL-a")]
        public string? VideoUrl { get; set; } = string.Empty;

        public List<IFormFile>? Images { get; set; } = new List<IFormFile>();
        public List<int>? ImagesToKeep { get; set; } = new List<int>();
    }
}