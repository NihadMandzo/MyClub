using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{

    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Content { get; set; }
        public string VideoUrl { get; set; }
        public List<string> ImageUrls { get; set; } = new List<string>();
        public DateTime Date { get; set; }
        public bool IsActive { get; set; }
        public List<NewsCommentResponse> Comments { get; set; } = new List<NewsCommentResponse>();
    }

    public class NewsCommentResponse
    {
        public int Id { get; set; }
        public string Content { get; set; }
        public DateTime Date { get; set; }
        public string UserName { get; set; }
    }
}