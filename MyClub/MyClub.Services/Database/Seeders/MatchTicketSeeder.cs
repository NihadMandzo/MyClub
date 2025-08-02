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

        int ticketId = 1;
        
        // Create exactly 1 ticket per sector per match (10 matches × 10 sectors = 100 tickets)
        for (int matchId = 1; matchId <= 10; matchId++)
        {
            for (int sectorId = 1; sectorId <= 10; sectorId++)
            {
                var matchDate = matchDates[matchId];

                int ReleasedQuantity = random.Next(0, 100);
                int availableQuantity = random.Next(0, ReleasedQuantity / 2);

                decimal price = Math.Round((decimal)(10 + random.NextDouble() * 40), 2);

                matchTickets.Add(new MatchTicket
                {
                    Id = ticketId,
                    MatchId = matchId,
                    StadiumSectorId = sectorId,
                    ReleasedQuantity = ReleasedQuantity,
                    AvailableQuantity = availableQuantity,
                    Price = price,
                });
                
                ticketId++;
            }
        }

        entity.HasData(matchTickets);
    }
}
