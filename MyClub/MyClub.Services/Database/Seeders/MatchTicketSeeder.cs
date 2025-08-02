using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class MatchTicketSeeder
{
    public static void SeedData(this EntityTypeBuilder<MatchTicket> entity)
    {
        var random = new Random(400);
        var matchTickets = new List<MatchTicket>();

        // Generišemo random datume za matchId-eve 1-10, da možemo znati da li su u prošlosti ili budućnosti
        var matchDates = new Dictionary<int, DateTime>();
        for (int i = 1; i <= 10; i++)
        {
            matchDates[i] = DateTime.Now.AddDays(random.Next(-180, 180));
        }

        for (int i = 1; i <= 50; i++)
        {
            int matchId = (i % 10) + 1; // MatchId 1-10
            int sectorId = (i % 10) + 1;

            var matchDate = matchDates[matchId];

            int totalQuantity = random.Next(100, 1001);
            int availableQuantity = matchDate < DateTime.Now
                ? random.Next(0, 50)
                : random.Next(totalQuantity / 2, totalQuantity + 1);

            decimal price = Math.Round((decimal)(10 + random.NextDouble() * 40), 2);

            matchTickets.Add(new MatchTicket
            {
                Id = i,
                MatchId = matchId,
                StadiumSectorId = sectorId,
                ReleasedQuantity = totalQuantity,
                Price = price,
                IsActive = matchDate >= DateTime.Now
            });
        }

        entity.HasData(matchTickets);
    }
}
