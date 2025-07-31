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
                new NewsAsset { NewsId = 2, AssetId = 3 },
                new NewsAsset { NewsId = 2, AssetId = 4 },

                // News 3 assets
                new NewsAsset { NewsId = 3, AssetId = 5},
                new NewsAsset { NewsId = 3, AssetId = 6 },

                // News 4 assets
                new NewsAsset { NewsId = 4, AssetId = 7 },
                new NewsAsset { NewsId = 4, AssetId = 8 },

                // News 5 assets                
                new NewsAsset { NewsId = 5, AssetId = 9 },
                new NewsAsset { NewsId = 5, AssetId = 10 },

                // News 6 assets
                new NewsAsset { NewsId = 6, AssetId = 11 },
                new NewsAsset { NewsId = 6, AssetId = 12 },

                // News 7 assets
                new NewsAsset { NewsId = 7, AssetId = 13 },
                new NewsAsset { NewsId = 7, AssetId = 14 },

                // News 8 assets
                new NewsAsset { NewsId = 8, AssetId = 15 },
                new NewsAsset { NewsId = 8, AssetId = 16 },

                // News 9 assets
                new NewsAsset { NewsId = 9, AssetId = 17 },
                new NewsAsset { NewsId = 9, AssetId = 18 },

                // News 10 assets
                new NewsAsset { NewsId = 10, AssetId = 19 },
                new NewsAsset { NewsId = 10, AssetId = 20 },
                // News 11 assets
                new NewsAsset { NewsId = 11, AssetId = 21 },
                new NewsAsset { NewsId = 11, AssetId = 22 },
                // News 12 assets
                new NewsAsset { NewsId = 12, AssetId = 23 },
                new NewsAsset { NewsId = 12, AssetId = 24 },
                // News 13 assets
                new NewsAsset { NewsId = 13, AssetId = 25 },
                new NewsAsset { NewsId = 13, AssetId = 26 },
                // News 14 assets
                new NewsAsset { NewsId = 14, AssetId = 27 },
                new NewsAsset { NewsId = 14, AssetId = 28 },
                // News 15 assets
                new NewsAsset { NewsId = 15, AssetId = 29 },
                new NewsAsset { NewsId = 15, AssetId = 30 },
                // News 16 assets
                new NewsAsset { NewsId = 16, AssetId = 31 },
                new NewsAsset { NewsId = 16, AssetId = 32 },
                // News 17 assets
                new NewsAsset { NewsId = 17, AssetId = 33 },
                new NewsAsset { NewsId = 17, AssetId = 34 },
                // News 18 assets
                new NewsAsset { NewsId = 18, AssetId = 35 },
                new NewsAsset { NewsId = 18, AssetId = 36 },
                // News 19 assets
                new NewsAsset { NewsId = 19, AssetId = 37 },
                new NewsAsset { NewsId = 19, AssetId = 38 },
                // News 20 assets
                new NewsAsset { NewsId = 20, AssetId = 39 },
                new NewsAsset { NewsId = 20, AssetId = 40 }
            );
        }
    }
}
