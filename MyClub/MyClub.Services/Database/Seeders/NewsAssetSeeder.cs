using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class NewsAssetSeeder
    {
        public static void SeedData(this EntityTypeBuilder<NewsAsset> entity)
        {
            entity.HasData(
                // News 1 assets
                new NewsAsset { NewsId = 1, AssetId = 1 },
                new NewsAsset { NewsId = 1, AssetId = 2 },
                new NewsAsset { NewsId = 1, AssetId = 3 },
                new NewsAsset { NewsId = 1, AssetId = 4 },

                // News 2 assets
                new NewsAsset { NewsId = 2, AssetId = 5 },
                new NewsAsset { NewsId = 2, AssetId = 6 },
                new NewsAsset { NewsId = 2, AssetId = 7 },
                new NewsAsset { NewsId = 2, AssetId = 8 },

                // News 3 assets
                new NewsAsset { NewsId = 3, AssetId = 9 },
                new NewsAsset { NewsId = 3, AssetId = 10 },
                new NewsAsset { NewsId = 3, AssetId = 11 },
                new NewsAsset { NewsId = 3, AssetId = 12 },

                // News 4 assets
                new NewsAsset { NewsId = 4, AssetId = 13 },
                new NewsAsset { NewsId = 4, AssetId = 14 },
                new NewsAsset { NewsId = 4, AssetId = 15 },
                new NewsAsset { NewsId = 4, AssetId = 16 },

                // News 5 assets                
                new NewsAsset { NewsId = 5, AssetId = 17 },
                new NewsAsset { NewsId = 5, AssetId = 18 },
                new NewsAsset { NewsId = 5, AssetId = 19 },
                new NewsAsset { NewsId = 5, AssetId = 20 },

                // News 6 assets
                new NewsAsset { NewsId = 6, AssetId = 21 },
                new NewsAsset { NewsId = 6, AssetId = 22 },
                new NewsAsset { NewsId = 6, AssetId = 23 },
                new NewsAsset { NewsId = 6, AssetId = 24 },

                // News 7 assets
                new NewsAsset { NewsId = 7, AssetId = 25 },
                new NewsAsset { NewsId = 7, AssetId = 26 },
                new NewsAsset { NewsId = 7, AssetId = 27 },
                new NewsAsset { NewsId = 7, AssetId = 28 },

                // News 8 assets
                new NewsAsset { NewsId = 8, AssetId = 29 },
                new NewsAsset { NewsId = 8, AssetId = 30 },
                new NewsAsset { NewsId = 8, AssetId = 31 },
                new NewsAsset { NewsId = 8, AssetId = 32 },

                // News 9 assets
                new NewsAsset { NewsId = 9, AssetId = 33 },
                new NewsAsset { NewsId = 9, AssetId = 34 },
                new NewsAsset { NewsId = 9, AssetId = 35 },
                new NewsAsset { NewsId = 9, AssetId = 36 },

                // News 10 assets
                new NewsAsset { NewsId = 10, AssetId = 37 },
                new NewsAsset { NewsId = 10, AssetId = 38 },
                new NewsAsset { NewsId = 10, AssetId = 39 },
                new NewsAsset { NewsId = 10, AssetId = 40 }
            );
        }
    }
}
