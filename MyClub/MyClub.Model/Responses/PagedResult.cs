using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class PagedResult<T>
    {
        public int TotalCount { get; set; }
        public int CurrentPage { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
        public bool HasPrevious => CurrentPage > 0;
        public bool HasNext => CurrentPage < TotalPages - 1;
        public List<T> Data { get; set; } = new List<T>();
    }
}