using System;

namespace MyClub.Model.SearchObjects
{
    public class MembershipCardSearchObject : BaseSearchObject
    {
        public int? Year { get; set; }
        public string? NameFTS { get; set; }
        public bool IncludeInactive { get; set; } = false;
    }
} 