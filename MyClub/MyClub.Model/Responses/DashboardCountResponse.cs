using System;

namespace MyClub.Model.Responses
{
    public class DashboardCountResponse
    {
        public int TotalCount { get; set; }
        public int ThisMonth { get; set; }
        public int LastMonth { get; set; }
        public decimal PercentageChange { get; set; }
    }
} 