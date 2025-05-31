using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class ProductSizeSeeder
{    public static void SeedData(this EntityTypeBuilder<ProductSize> entity)
    {
        var productSizeData = new List<ProductSize>();
        var id = 1;

        // Products from 1 to 15
        for (int productId = 1; productId <= 15; productId++)
        {
            // Sizes from 1 to 7
            for (int sizeId = 1; sizeId <= 7; sizeId++)
            {
                productSizeData.Add(new ProductSize
                {
                    Id = id++,
                    ProductId = productId,
                    SizeId = sizeId,
                    Quantity = 10
                });
            }
        }

        entity.HasData(productSizeData.ToArray());
    }
}
