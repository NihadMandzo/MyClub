using System;

namespace MyClub.Model.Responses
{
    public class UserTicketResponse
    {
        public int Id { get; set; }
        public decimal TotalPrice { get; set; }
        public DateTime PurchaseDate { get; set; }
        public string QRCodeData { get; set; }

        public bool IsValid { get; set; }

        // Match Info
        public int MatchId { get; set; }
        public string OpponentName { get; set; }
        public DateTime MatchDate { get; set; }
        public string Location { get; set; }
        
        // Sector Info
        public string SectorCode { get; set; }
        public string StadiumSide { get; set; }
    }
} 