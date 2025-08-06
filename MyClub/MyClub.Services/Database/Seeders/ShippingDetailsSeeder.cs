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
        
        // Cities will be from Bosnia and Herzegovina (CountryId = 1)
        int maxCityId = 20; // We have 20 cities from Bosnia and Herzegovina
        
        for (int i = 1; i <= 20; i++)
        {
            int cityId = random.Next(1, maxCityId + 1);
            
            shippingDetails.Add(new ShippingDetails
            {
                Id = i,
                ShippingAddress = streets[random.Next(0, streets.Length)],
                CityId = cityId
            });
        }

        entity.HasData(shippingDetails);
    }
}
