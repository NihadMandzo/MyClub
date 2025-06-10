using System;

namespace MyClub.Model.SearchObjects
{
    public class PlayerSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? ClubId { get; set; }
        public string? Position { get; set; }
    }
}