using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public AssetResponse? PrimaryImage { get; set; }
        public string? VideoUrl { get; set; }
        public string Content { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public List<AssetResponse> Images { get; set; } = new List<AssetResponse>();
        public List<CommentResponse> Comments { get; set; } = new List<CommentResponse>();
    }


}