using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class MembershipCardSeeder
{
    public static void SeedData(this EntityTypeBuilder<MembershipCard> entity)
    {
        var random = new Random(200);
        var membershipCards = new List<MembershipCard>();
        
        string[] cardTypes = { "Standard", "Silver", "Gold", "Platinum", "Diamond" };
        string[] benefitsList = {
            "Free entry to home matches, 10% discount in club shop",
            "Free entry to home matches, 15% discount in club shop, priority ticket purchase",
            "Free entry to all matches, 20% discount in club shop, meet players once a year",
            "Free entry to all matches, 25% discount in club shop, VIP lounge access",
            "Full season access to all events, 30% discount in club shop, personal player meet & greet"
        };

        for (int i = 1; i <= 50; i++)
        {
            int year = 2020 + random.Next(0, 6); // Years from 2020 to 2025
            int targetMembers = random.Next(500, 5001);
            int totalMembers = random.Next(0, targetMembers + 1);
            
            var cardName = $"{cardTypes[random.Next(0, cardTypes.Length)]} Membership {year}";
            var price = Math.Round((decimal)(random.Next(50, 501)), 2);
            
            var startDate = new DateTime(year, 1, 1);
            var endDate = new DateTime(year, 12, 31);
            
            // Image IDs start from around 73 based on your context
            var imageId = 73 + random.Next(0, 10);
            
            membershipCards.Add(new MembershipCard
            {
                Id = i,
                Year = year,
                Name = cardName,
                Description = $"{cardName} - Support your club with our {year} membership program",
                TotalMembers = totalMembers,
                TargetMembers = targetMembers,
                Price = price,
                StartDate = startDate,
                EndDate = endDate,
                Benefits = benefitsList[random.Next(0, benefitsList.Length)],
                ImageId = imageId,
                IsActive = year >= DateTime.Now.Year
            });
        }

        entity.HasData(membershipCards);
    }
}
