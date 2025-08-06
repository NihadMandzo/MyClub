using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class CitySeeder
    {
        public static void SeedData(this EntityTypeBuilder<City> entity)
        {
            // Bosnia and Herzegovina cities (CountryId = 1)
            var cities = new List<City>
            {
                // Bosnia and Herzegovina
                new City { Id = 1, Name = "Sarajevo", PostalCode = "71000", CountryId = 1 },
                new City { Id = 2, Name = "Banja Luka", PostalCode = "78000", CountryId = 1 },
                new City { Id = 3, Name = "Tuzla", PostalCode = "75000", CountryId = 1 },
                new City { Id = 4, Name = "Zenica", PostalCode = "72000", CountryId = 1 },
                new City { Id = 5, Name = "Mostar", PostalCode = "88000", CountryId = 1 },
                new City { Id = 6, Name = "Bijeljina", PostalCode = "76300", CountryId = 1 },
                new City { Id = 7, Name = "Prijedor", PostalCode = "79101", CountryId = 1 },
                new City { Id = 8, Name = "Brčko", PostalCode = "76100", CountryId = 1 },
                new City { Id = 9, Name = "Doboj", PostalCode = "74000", CountryId = 1 },
                new City { Id = 10, Name = "Bihać", PostalCode = "77000", CountryId = 1 },
                new City { Id = 11, Name = "Foča", PostalCode = "73300", CountryId = 1 },
                new City { Id = 12, Name = "Trebinje", PostalCode = "89101", CountryId = 1 },
                new City { Id = 13, Name = "Goražde", PostalCode = "73000", CountryId = 1 },
                new City { Id = 14, Name = "Livno", PostalCode = "80101", CountryId = 1 },
                new City { Id = 15, Name = "Cazin", PostalCode = "77220", CountryId = 1 },
                new City { Id = 16, Name = "Visoko", PostalCode = "71300", CountryId = 1 },
                new City { Id = 17, Name = "Gradačac", PostalCode = "76250", CountryId = 1 },
                new City { Id = 18, Name = "Konjic", PostalCode = "88400", CountryId = 1 },
                new City { Id = 19, Name = "Višegrad", PostalCode = "73240", CountryId = 1 },
                new City { Id = 20, Name = "Gračanica", PostalCode = "75320", CountryId = 1 },
                
                // Croatia
                new City { Id = 21, Name = "Zagreb", PostalCode = "10000", CountryId = 2 },
                new City { Id = 22, Name = "Split", PostalCode = "21000", CountryId = 2 },
                new City { Id = 23, Name = "Rijeka", PostalCode = "51000", CountryId = 2 },
                new City { Id = 24, Name = "Osijek", PostalCode = "31000", CountryId = 2 },
                new City { Id = 25, Name = "Zadar", PostalCode = "23000", CountryId = 2 },
                
                // Serbia
                new City { Id = 26, Name = "Belgrade", PostalCode = "11000", CountryId = 3 },
                new City { Id = 27, Name = "Novi Sad", PostalCode = "21000", CountryId = 3 },
                new City { Id = 28, Name = "Niš", PostalCode = "18000", CountryId = 3 },
                new City { Id = 29, Name = "Kragujevac", PostalCode = "34000", CountryId = 3 },
                new City { Id = 30, Name = "Subotica", PostalCode = "24000", CountryId = 3 },
                
                // Montenegro
                new City { Id = 31, Name = "Podgorica", PostalCode = "81000", CountryId = 4 },
                new City { Id = 32, Name = "Nikšić", PostalCode = "81400", CountryId = 4 },
                new City { Id = 33, Name = "Herceg Novi", PostalCode = "85340", CountryId = 4 },
                
            };
            
            entity.HasData(cities);
        }
    }
}
