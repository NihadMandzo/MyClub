using System;

namespace MyClub.Model.SearchObjects
{

    public class NewsSearchObject : BaseSearchObject
    {
        public string? Title { get; set; }
        public string? Content { get; set; }
    }
}