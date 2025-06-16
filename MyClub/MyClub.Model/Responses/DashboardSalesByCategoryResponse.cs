using System;

namespace MyClub.Model.Responses
{
    public class DashboardSalesByCategoryResponse
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; }
        public int TotalSold { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal Percentage { get; set; }
    }
} 