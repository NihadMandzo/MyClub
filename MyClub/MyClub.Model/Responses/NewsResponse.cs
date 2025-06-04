using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public NewsImageResponse? PrimaryImage { get; set; }
    }

    public class NewsByIdResponse : NewsResponse
    {
        public string Content { get; set; } = string.Empty;
        public string? VideoUrl { get; set; }
        public new List<NewsImageResponse> PrimaryImage { get; set; } = new List<NewsImageResponse>();
        public List<NewsCommentResponse> Comments { get; set; } = new List<NewsCommentResponse>();
        public string Username { get; set; } = string.Empty;
    }

    public class NewsImageResponse
    {
        public int AssetId { get; set; }
        public string Url { get; set; } = string.Empty;
    }

    public class NewsCommentResponse
    {
        public int Id { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public string UserName { get; set; } = string.Empty;
    }
}