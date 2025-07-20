using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class ShippingDetailsSeeder
{
    public static void SeedData(this EntityTypeBuilder<ShippingDetails> entity)
    {
        var random = new Random(800);
        var shippingDetails = new List<ShippingDetails>();
        
        string[] streets = {
            "123 Main Street", "456 Elm Avenue", "789 Oak Drive", "321 Pine Boulevard",
            "654 Maple Road", "987 Cedar Lane", "246 Birch Street", "135 Walnut Avenue",
            "864 Spruce Court", "975 Willow Way", "753 Poplar Place", "159 Cherry Drive",
            "357 Aspen Circle", "486 Sycamore Street", "219 Redwood Road", "852 Juniper Lane"
        };
        
        string[] cities = {
            "Sarajevo", "Banja Luka", "Tuzla", "Zenica", "Mostar", "Bijeljina", 
            "Prijedor", "Brčko", "Doboj", "Bihać", "Foča", "Trebinje", "Goražde",
            "Livno", "Cazin", "Visoko", "Gradačac", "Konjic", "Višegrad", "Gračanica"
        };
        
        string[] postalCodes = {
            "71000", "78000", "75000", "72000", "88000", "76300", 
            "79101", "76100", "74000", "77000", "73300", "89101",
            "73000", "80101", "77220", "71300", "76250", "88400", "73240", "75320"
        };
        
        for (int i = 1; i <= 20; i++)
        {
            var city = cities[random.Next(0, cities.Length)];
            var postalCodeIndex = Array.IndexOf(cities, city) % postalCodes.Length;
            var postalCode = postalCodes[postalCodeIndex];
            
            shippingDetails.Add(new ShippingDetails
            {
                Id = i,
                ShippingAddress = streets[random.Next(0, streets.Length)],
                ShippingCity = city,
                ShippingPostalCode = postalCode,
                ShippingCountry = "Bosnia and Herzegovina"
            });
        }

        entity.HasData(shippingDetails);
    }
}
