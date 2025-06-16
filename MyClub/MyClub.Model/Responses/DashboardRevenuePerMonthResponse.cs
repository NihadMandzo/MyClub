using System;

namespace MyClub.Model.Responses
{
    public class DashboardRevenuePerMonthResponse
    {
        public string Month { get; set; }
        public int Year { get; set; }
        public string MonthName { get; set; }
        public decimal TotalAmount { get; set; }
        public string Currency { get; set; } = "BAM";
    }
} 