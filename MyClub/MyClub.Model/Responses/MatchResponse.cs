using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class MatchResponse
    {
        public int Id { get; set; }
        public DateTime MatchDate { get; set; }
        public bool IsHomeMatch { get; set; }
        public string OpponentName { get; set; }
        public int? HomeGoals { get; set; }
        public int? AwayGoals { get; set; }
        public string Status { get; set; }
        public int ClubId { get; set; }
        public string ClubName { get; set; }
        public string Result { get; set; }
        public List<MatchTicketResponse> Tickets { get; set; } = new List<MatchTicketResponse>();
    }
} 