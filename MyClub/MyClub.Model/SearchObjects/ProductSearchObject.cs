using System;
using System.Collections.Generic;
using System.Text;

namespace MyClub.Model.SearchObjects
{
    public class ProductSearchObject : BaseSearchObject
    {
        public string? BarCode { get; set; }
        public List<int>? CategoryIds { get; set; }
        public List<int>? ColorIds { get; set; }
        public List<int>? SizeIds { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
    }
}