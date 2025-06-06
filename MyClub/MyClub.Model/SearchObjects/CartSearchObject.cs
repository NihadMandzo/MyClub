using System;

namespace MyClub.Model.SearchObjects
{
    public class CartSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public bool? IncludeItems { get; set; } = true;
    }
} 