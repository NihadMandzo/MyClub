using System;

namespace MyClub.Model.Requests
{
    public class CommentUpsertRequest
    {
        public string Content { get; set; }
        public int NewsId { get; set; }
    }
}