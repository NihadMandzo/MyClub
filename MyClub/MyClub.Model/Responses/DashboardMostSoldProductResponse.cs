using System;

namespace MyClub.Model.Responses
{
    public class DashboardMostSoldProductResponse
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; }
        public string Category { get; set; }
        public int TotalSold { get; set; }
        public decimal TotalRevenue { get; set; }
        public string ImageUrl { get; set; }
    }
} 