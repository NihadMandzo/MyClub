using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class NewsUpsertRequest
    {
        [Required(ErrorMessage = "Title is required")]
        [StringLength(200, MinimumLength = 3, ErrorMessage = "Title must be between 3 and 200 characters")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Content is required")]
        [MinLength(10, ErrorMessage = "Content must be at least 10 characters long")]
        public string Content { get; set; } = string.Empty;

        [Url(ErrorMessage = "Invalid video URL format")]
        public string? VideoUrl { get; set; } = string.Empty;

        public List<IFormFile>? Images { get; set; } = new List<IFormFile>();
        public List<int>? ImagesToKeep { get; set; } = new List<int>();
    }
}