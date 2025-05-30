using System;

namespace MyClub.Model.Responses
{

    public class CommentResponse
    {
        public string Content {get;set;}
        public DateTime CreatedAt {get;set;}
        public string UserName {get;set;}
    }
}