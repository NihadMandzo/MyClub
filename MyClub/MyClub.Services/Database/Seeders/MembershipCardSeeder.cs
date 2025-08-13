using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class MembershipCardSeeder
{
    public static void SeedData(this EntityTypeBuilder<MembershipCard> entity)
    {
        var random = new Random(200);
        var membershipCards = new List<MembershipCard>();

        string[] cardTypes = { "Standard", "Srebrena", "Zlatna", "Platinum" };
        string[] benefitsList = {
            "Dzaba ulaz na domaće utakmice, 10% popusta u klupskom dućanu",
            "Dzaba ulaz na domaće utakmicehes, 15% popusta u klupskom dućanu, prioritetna kupovina karata",
            "Dzaba ulaz na sve utakmice, 20% popusta u klupskom dućanu, susret s igračima jednom godišnje",
            "Dzaba ulaz na sve utakmice, 25% popusta u klupskom dućanu, pristup VIP loži",
            "Puni pristup svim događanjima, 30% popusta u klupskom dućanu, osobni susret s igračem"
        };

        for (int i = 1; i <= 4; i++)
        {
            int year = 2021 + i; // Years from 2021 to 2025
            int targetMembers = random.Next(500, 5001);
            int totalMembers = random.Next(0, targetMembers + 1);

            var cardName = $"{cardTypes[random.Next(0, cardTypes.Length)]} Članstvo {year}";
            var price = Math.Round((decimal)(random.Next(50, 501)), 2);

            var startDate = new DateTime(year, 1, 1);
            var endDate = new DateTime(year, 12, 31);

            var imageId = 98 + i; // Assuming images are seeded from ID 99 onwards

            membershipCards.Add(new MembershipCard
            {
                Id = i,
                Year = year,
                Name = cardName,
                Description = $"{cardName} - Podržite svoj klub s našim {year} članstvom!",
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
