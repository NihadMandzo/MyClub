using System;

namespace MyClub.Model.SearchObjects
{
    public class MatchSearchObject : BaseSearchObject
    {
        public int? ClubId { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public bool? IsHomeMatch { get; set; }
        public string Status { get; set; }
        public bool? IncludeTickets { get; set; } = true;
        public bool? UpcomingOnly { get; set; }
    }
} 