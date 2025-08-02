using System;

namespace MyClub.Model
{
    public class StadiumSectorResponse
    {
        public int Id { get; set; }
        public int Capacity { get; set; }
        public string Code { get; set; } // A1, A2, B1, B2, B3, etc.
        public string SideName { get; set; }
    }
}