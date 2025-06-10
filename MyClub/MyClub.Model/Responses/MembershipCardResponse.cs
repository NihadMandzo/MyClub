using System;

namespace MyClub.Model.Responses
{
    public class MembershipCardResponse
    {
        public int Id { get; set; }
        public int Year { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public int TotalMembers { get; set; }
        public int TargetMembers { get; set; }
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Benefits { get; set; }
        public string ImageUrl { get; set; }
        public bool IsActive { get; set; }
        public bool IsCurrent { get; set; }
        public double ProgressPercentage => TargetMembers > 0 ? Math.Min(100, (TotalMembers * 100.0 / TargetMembers)) : 0;
    }
} 