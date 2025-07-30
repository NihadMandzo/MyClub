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

                // News 2 assets
                new NewsAsset { NewsId = 2, AssetId = 4 },
                new NewsAsset { NewsId = 2, AssetId = 5 },

                // News 3 assets
                new NewsAsset { NewsId = 3, AssetId = 6 },
                new NewsAsset { NewsId = 3, AssetId = 7 },

                // News 4 assets
                new NewsAsset { NewsId = 4, AssetId = 8 },
                new NewsAsset { NewsId = 4, AssetId = 9 },

                // News 5 assets                
                new NewsAsset { NewsId = 5, AssetId = 10 },
                new NewsAsset { NewsId = 5, AssetId = 11 },

                // News 6 assets
                new NewsAsset { NewsId = 6, AssetId = 12 },
                new NewsAsset { NewsId = 6, AssetId = 13 },

                // News 7 assets
                new NewsAsset { NewsId = 7, AssetId = 14 },
                new NewsAsset { NewsId = 7, AssetId = 15 },

                // News 8 assets
                new NewsAsset { NewsId = 8, AssetId = 16 },
                new NewsAsset { NewsId = 8, AssetId = 17 },

                // News 9 assets
                new NewsAsset { NewsId = 9, AssetId = 18 },
                new NewsAsset { NewsId = 9, AssetId = 19 },

                // News 10 assets
                new NewsAsset { NewsId = 10, AssetId = 20 },
                new NewsAsset { NewsId = 10, AssetId = 21 },
                // News 11 assets
                new NewsAsset { NewsId = 11, AssetId = 22 },
                new NewsAsset { NewsId = 11, AssetId = 23 },
                // News 12 assets
                new NewsAsset { NewsId = 12, AssetId = 24 },
                new NewsAsset { NewsId = 12, AssetId = 25 },
                // News 13 assets
                new NewsAsset { NewsId = 13, AssetId = 26 },
                new NewsAsset { NewsId = 13, AssetId = 27 },
                // News 14 assets
                new NewsAsset { NewsId = 14, AssetId = 28 },
                new NewsAsset { NewsId = 14, AssetId = 29 },
                // News 15 assets
                new NewsAsset { NewsId = 15, AssetId = 30 },
                new NewsAsset { NewsId = 15, AssetId = 31 },
                // News 16 assets
                new NewsAsset { NewsId = 16, AssetId = 32 },
                new NewsAsset { NewsId = 16, AssetId = 33 },
                // News 17 assets
                new NewsAsset { NewsId = 17, AssetId = 34 },
                new NewsAsset { NewsId = 17, AssetId = 35 },
                // News 18 assets
                new NewsAsset { NewsId = 18, AssetId = 36 },
                new NewsAsset { NewsId = 18, AssetId = 37 },
                // News 19 assets
                new NewsAsset { NewsId = 19, AssetId = 38 },
                new NewsAsset { NewsId = 19, AssetId = 39 },
                // News 20 assets
                new NewsAsset { NewsId = 20, AssetId = 40 },
                new NewsAsset { NewsId = 20, AssetId = 41 }
            );
        }
    }
}
