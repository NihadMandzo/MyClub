using System;

namespace MyClub.Model.Responses
{

    public class CommentResponse
    {
        public int Id { get; set; }
        public string Content { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Username { get; set; }
    }
}