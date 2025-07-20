using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class StadiumSectorSeeder
    {
        public static void SeedData(this EntityTypeBuilder<StadiumSector> entity)
        {
            entity.HasData(
                new StadiumSector { Id = 1, Code = "A1", Capacity = 100, StadiumSideId = 1 },
                new StadiumSector { Id = 2, Code = "A2", Capacity = 100, StadiumSideId = 1 },
                new StadiumSector { Id = 3, Code = "B1", Capacity = 100, StadiumSideId = 2 },
                new StadiumSector { Id = 4, Code = "B2", Capacity = 100, StadiumSideId = 2 },
                new StadiumSector { Id = 5, Code = "C1", Capacity = 100, StadiumSideId = 3 },
                new StadiumSector { Id = 6, Code = "C2", Capacity = 100, StadiumSideId = 3 },
                new StadiumSector { Id = 7, Code = "C3", Capacity = 100, StadiumSideId = 3 },
                new StadiumSector { Id = 8, Code = "D1", Capacity = 100, StadiumSideId = 4 },
                new StadiumSector { Id =9, Code = "D2", Capacity = 100, StadiumSideId = 4 },
                new StadiumSector { Id = 10, Code = "D3", Capacity = 100, StadiumSideId = 4 }
            );
        }
    }
}