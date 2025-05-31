using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class ProductAssetSeeder
    {
        public static void SeedData(this EntityTypeBuilder<ProductAsset> entity)
        {
            entity.HasData(
                // Product 1 - Domaći Dres
                new ProductAsset { ProductId = 1, AssetId = 41 },
                new ProductAsset { ProductId = 1, AssetId = 42 },
                // Product 2 - Gostujući Dres
                new ProductAsset { ProductId = 2, AssetId = 43 },
                new ProductAsset { ProductId = 2, AssetId = 44 },
                // Product 3 - Casual Majica
                new ProductAsset { ProductId = 3, AssetId = 45 },
                new ProductAsset { ProductId = 3, AssetId = 46 },
                // Product 4 - Duks
                new ProductAsset { ProductId = 4, AssetId = 47 },
                new ProductAsset { ProductId = 4, AssetId = 48 },
                // Product 5 - Šorc
                new ProductAsset { ProductId = 5, AssetId = 49 },
                new ProductAsset { ProductId = 5, AssetId = 50 },
                // Product 6 - Kapa
                new ProductAsset { ProductId = 6, AssetId = 51 },
                new ProductAsset { ProductId = 6, AssetId = 52 },
                // Product 7 - Šal
                new ProductAsset { ProductId = 7, AssetId = 53 },
                new ProductAsset { ProductId = 7, AssetId = 54 },
                // Product 8 - Privjesak
                new ProductAsset { ProductId = 8, AssetId = 55 },
                new ProductAsset { ProductId = 8, AssetId = 56 },
                // Product 9 - Baby Set
                new ProductAsset { ProductId = 9, AssetId = 57 },
                new ProductAsset { ProductId = 9, AssetId = 58 },
                // Product 10 - Zastava
                new ProductAsset { ProductId = 10, AssetId = 59 },
                new ProductAsset { ProductId = 10, AssetId = 60 },
                // Product 11 - Retro Dres
                new ProductAsset { ProductId = 11, AssetId = 61 },
                new ProductAsset { ProductId = 11, AssetId = 62 },
                // Product 12 - Treći Dres
                new ProductAsset { ProductId = 12, AssetId = 63 },
                new ProductAsset { ProductId = 12, AssetId = 64 },
                // Product 13 - Polo Majica
                new ProductAsset { ProductId = 13, AssetId = 65 },
                new ProductAsset { ProductId = 13, AssetId = 66 },
                // Product 14 - Dječiji Set
                new ProductAsset { ProductId = 14, AssetId = 67 },
                new ProductAsset { ProductId = 14, AssetId = 68 },
                // Product 15 - Zimska Jakna
                new ProductAsset { ProductId = 15, AssetId = 69 },
                new ProductAsset { ProductId = 15, AssetId = 70 }
            );
        }
    }
}
