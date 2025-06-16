using System;

namespace MyClub.Model.Responses
{
    public class DashboardMembershipPerMonthResponse
    {
        public string Month { get; set; }
        public int Year { get; set; }
        public string MonthName { get; set; }
        public int Count { get; set; }
    }
} 