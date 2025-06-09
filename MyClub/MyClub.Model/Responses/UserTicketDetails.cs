using System;

namespace MyClub.Model.Responses
{
    public class UserTicketDetails
    {
        public int TicketId { get; set; }
        public string Username { get; set; }
        public int Quantity { get; set; }
        public string MatchInfo { get; set; }
        public string SectorInfo { get; set; }
        public DateTime PurchaseDate { get; set; }
    }
} 