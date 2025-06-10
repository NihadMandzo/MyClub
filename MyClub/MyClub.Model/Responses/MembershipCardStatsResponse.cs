using System;

namespace MyClub.Model.Responses
{
    public class MembershipCardStatsResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int Year { get; set; }
        public int TotalMembers { get; set; }
        public int TargetMembers { get; set; }
        public int NewMemberships { get; set; }
        public int RenewedMemberships { get; set; }
        public int PhysicalCardsRequested { get; set; }
        public int PhysicalCardsShipped { get; set; }
        public decimal TotalRevenue { get; set; }
        public double ProgressPercentage => TargetMembers > 0 ? Math.Min(100, (TotalMembers * 100.0 / TargetMembers)) : 0;
    }
} 