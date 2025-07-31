using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class UserMembershipSeeder
{
    public static void SeedData(this EntityTypeBuilder<UserMembership> entity)
    {
        var random = new Random(500);
        var userMemberships = new List<UserMembership>();
        
        string[] firstNames = { "John", "Michael", "David", "James", "Robert", "William", "Mary", "Patricia", "Linda", "Barbara" };
        string[] lastNames = { "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez" };
        
        for (int i = 1; i <= 50; i++)
        {
            int userId = random.Next(1, 4); // User IDs from your UserSeeder
            int membershipCardId = random.Next(1, 5); // MembershipCard IDs from MembershipCardSeeder
            int paymentId = i; // Payment IDs from PaymentSeeder
            
            var joinDate = DateTime.Now.AddDays(-random.Next(1, 365));
            bool isRenewal = random.Next(0, 10) < 3; // 30% are renewals
            int? previousMembershipId = isRenewal ? random.Next(1, 5) : null;
            
            bool physicalCardRequested = random.Next(0, 10) < 7; // 70% want physical cards
            int? shippingDetailsId = physicalCardRequested ? random.Next(1, 20) : null;
            
            bool isShipped = shippingDetailsId.HasValue && random.Next(0, 10) < 8; // 80% of physical cards are shipped
            DateTime? shippedDate = isShipped ? joinDate.AddDays(random.Next(1, 14)) : null;
            
            bool isPaid = random.Next(0, 10) < 9; // 90% are paid
            DateTime? paymentDate = isPaid ? joinDate : null;
            
            bool forFriend = random.Next(0, 10) < 2; // 20% are for friends
            string recipientFirstName = forFriend ? firstNames[random.Next(0, firstNames.Length)] : string.Empty;
            string recipientLastName = forFriend ? lastNames[random.Next(0, lastNames.Length)] : string.Empty;
            string recipientEmail = forFriend ? $"{recipientFirstName.ToLower()}.{recipientLastName.ToLower()}@example.com" : string.Empty;
            
            userMemberships.Add(new UserMembership
            {
                Id = i,
                UserId = userId,
                MembershipCardId = membershipCardId,
                PaymentId = paymentId,
                JoinDate = joinDate,
                RecipientFirstName = recipientFirstName,
                RecipientLastName = recipientLastName,
                RecipientEmail = recipientEmail,
                IsRenewal = isRenewal,
                PreviousMembershipId = previousMembershipId,
                PhysicalCardRequested = physicalCardRequested,
                ShippingDetailsId = shippingDetailsId,
                IsShipped = isShipped,
                ShippedDate = shippedDate,
                IsPaid = isPaid,
                PaymentDate = paymentDate
            });
        }

        entity.HasData(userMemberships);
    }
}
