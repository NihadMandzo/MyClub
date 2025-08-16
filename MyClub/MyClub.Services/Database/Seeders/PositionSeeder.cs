using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class PositionSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Position> entity)
        {
            var positions = new List<Position>
            {
                new Position { Id = 1, Name = "Golman", IsPlayer = true },
                new Position { Id = 2, Name = "Štoper", IsPlayer = true },
                new Position { Id = 3, Name = "Bek", IsPlayer = true },
                new Position { Id = 4, Name = "Vezni", IsPlayer = true },
                new Position { Id = 5, Name = "Krilo", IsPlayer = true },
                new Position { Id = 6, Name = "Napadač", IsPlayer = true },
                new Position { Id = 7, Name = "Trener", IsPlayer = false },
            };

            entity.HasData(positions);
        }
    }
}

          