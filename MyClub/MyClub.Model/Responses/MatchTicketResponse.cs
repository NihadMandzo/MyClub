using System;

namespace MyClub.Model
{
    public class MatchTicketResponse
    {
        public int Id { get; set; }
        public int MatchId { get; set; }
        public StadiumSectorResponse StadiumSector { get; set; }
        public int ReleasedQuantity { get; set; }
        public decimal Price { get; set; }
        public int AvailableQuantity { get; set; }
        public int UsedQuantity { get; set; }
    }
} 