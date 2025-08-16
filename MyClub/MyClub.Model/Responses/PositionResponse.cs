using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class PositionResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public bool IsPlayer { get; set; } = true;
        
    }
} 