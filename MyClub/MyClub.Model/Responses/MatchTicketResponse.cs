using System;

namespace MyClub.Model.Responses
{
    public class MatchTicketResponse
    {
        public int Id { get; set; }
        public int MatchId { get; set; }
        public int TotalQuantity { get; set; }
        public int AvailableQuantity { get; set; }
        public decimal Price { get; set; }
        public int StadiumSectorId { get; set; }
        public string SectorName { get; set; }
        public string SectorColor { get; set; }
    }
} 