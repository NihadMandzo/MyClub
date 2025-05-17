using System;
using System.Collections.Generic;
using System.Text;

namespace MyClub.Model.SearchObjects
{
    public class ProductTypeSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        
        public bool? IsActive { get; set; }
    }
} 