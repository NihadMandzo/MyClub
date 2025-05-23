using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class PagedResult<T>
    {
        public int TotalCount { get; set; }
        public List<T> Data { get; set; } = new List<T>();
    }
}