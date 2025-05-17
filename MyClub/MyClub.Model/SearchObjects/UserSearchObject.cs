using System;
using System.Collections.Generic;
using System.Text;

namespace MyClub.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Username { get; set; }
        
        public string? Email { get; set; }
        
        public string? FirstName { get; set; }
        
        public string? LastName { get; set; }
        
        public bool? IsActive { get; set; }
    }
} 