using System;

namespace MyClub.Model.Responses
{
    public class PlayerResponse
    {
        public int Id { get; set; }
        public string FullName { get; set; }
        public string Position { get; set; }
        public int Age { get; set; }
        public string Nationality { get; set; }
        public string ImageUrl { get; set; }
        public int Height { get; set; } // Height in centimeters
        public int Weight { get; set; } // Weight in kilograms
        public string Biography { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public int Number { get; set; } // Player's jersey number
    }
}