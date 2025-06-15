using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyClub.Services.Helpers
{
    public static class DiscountHelper
    {
        public const decimal MEMBERSHIP_DISCOUNT_PERCENTAGE = 0.2m; // 20% discount
        
        public static async Task<bool> HasActiveUserMembership(MyClubContext context, int userId)
        {
            var currentDate = DateTime.UtcNow;
            
            // Get the latest active membership for the user
            var activeMembership = await context.UserMemberships
                .Include(um => um.MembershipCard)
                .Where(um => um.UserId == userId && 
                       um.MembershipCard.IsActive && 
                       um.MembershipCard.StartDate <= currentDate && 
                       um.MembershipCard.EndDate >= currentDate)
                .OrderByDescending(um => um.JoinDate)
                .FirstOrDefaultAsync();
                
            return activeMembership != null;
        }
        
        public static async Task<decimal> ApplyMembershipDiscountIfApplicable(MyClubContext context, int userId, decimal originalAmount)
        {
            bool hasActiveMembership = await HasActiveUserMembership(context, userId);
            
            if (hasActiveMembership)
            {
                return Math.Round(originalAmount * (1 - MEMBERSHIP_DISCOUNT_PERCENTAGE), 2);
            }
            
            return originalAmount;
        }
    }
} 