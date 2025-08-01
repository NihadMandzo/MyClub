using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class MatchSeeder
{
    public static void SeedData(this EntityTypeBuilder<Match> entity)
    {
        var random = new Random(300);
        var matches = new List<Match>();
        
        string[] opponents = {
            "FC Sarajevo", "FK Željezničar", "FK Borac", "FK Sloboda", 
            "HŠK Zrinjski", "NK Široki Brijeg", "FK Radnik", "FK Mladost", 
            "NK Čelik", "FK Tuzla City", "FK Krupa", "NK Posušje", 
            "FK Velež", "FK Olimpik", "FK Rudar", "FK GOŠK"
        };
        
        string[] locations = {
            "Drinska Dolina, Foča", "Koševo, Sarajevo", "Grbavica, Sarajevo", 
            "Gradski stadion, Banja Luka", "Tušanj, Tuzla", "Bijeli brijeg, Mostar", 
            "Pecara, Široki Brijeg", "Gradski stadion, Bijeljina", "Vrapčići, Mostar"
        };
        
        string[] statuses = { "Zakazana", "Završena", "Otkazana", "Odgođena", "Uživo" };
        
        for (int i = 1; i <= 50; i++)
        {
            var matchDate = DateTime.Now.AddDays(random.Next(-180, 180)); // Matches in the past and future
            var opponentName = opponents[random.Next(0, opponents.Length)];
            var location = locations[random.Next(0, locations.Length)];
            
            // Past matches have Completed or Cancelled status, future matches are Scheduled
            string status;
            if (matchDate < DateTime.Now)
            {
                status = random.Next(0, 10) < 8 ? "Završena" : "Otkazana";
            }
            else if (matchDate.Date == DateTime.Now.Date)
            {
                status = random.Next(0, 10) < 5 ? "Uživo" : "Zakazana";
            }
            else
            {
                status = random.Next(0, 10) < 8 ? "Zakazana" : "Odgođena";
            }
            
            matches.Add(new Match
            {
                Id = i,
                MatchDate = matchDate,
                OpponentName = opponentName,
                Location = location,
                Status = status,
                Description = $"Utakmica protiv {opponentName} na {location}",
                ClubId = 1 // Assuming FK Foča with ID 1 from your ClubSeeder
            });
        }

        entity.HasData(matches);
    }
}
