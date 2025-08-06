using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class CountrySeeder
    {
        public static void SeedData(this EntityTypeBuilder<Country> entity)
        {
            entity.HasData(
                new Country
                {
                    Id = 1,
                    Name = "Bosna i Hercegovina",
                    Code = "BA"
                },
                new Country
                {
                    Id = 2,
                    Name = "Hrvatska",
                    Code = "HR"
                },
                new Country
                {
                    Id = 3,
                    Name = "Srbija",
                    Code = "RS"
                },
                new Country
                {
                    Id = 4,
                    Name = "Crna Gora",
                    Code = "ME"
                }
            );
        }
    }
}
