using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public class MatchResponse
    {
        public int Id { get; set; }
        public DateTime MatchDate { get; set; }
        public string OpponentName { get; set; }
        public string Status { get; set; }
        public int ClubId { get; set; }
        public string ClubName { get; set; }
        public string Location { get; set; }
        public string Description { get; set; }
        public List<MatchTicketResponse> Tickets { get; set; } = new List<MatchTicketResponse>();
    }


} 