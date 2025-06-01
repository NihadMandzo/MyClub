using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class NewsUpsertRequest
    {
        public string Title { get; set; }
        public string Content { get; set; }
        public string? VideoUrl { get; set; }
        public List<IFormFile> Images { get; set; } = new List<IFormFile>();
        public List<int> ImagesToKeep { get; set; } = new List<int>();
    }
}