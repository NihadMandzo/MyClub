using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class StadiumSideSeeder
    {
        public static void SeedData(this EntityTypeBuilder<StadiumSide> entity)
        {
            entity.HasData(
                new StadiumSide { Id = 1, Name = "Sjever" },
                new StadiumSide { Id = 2, Name = "Jug" },
                new StadiumSide { Id = 3, Name = "Istok" },
                new StadiumSide { Id = 4, Name = "Zapad" }
            );
        }
    }
}