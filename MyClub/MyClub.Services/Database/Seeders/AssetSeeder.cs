using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class AssetSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Asset> entity)
        {
            entity.HasData(
                new Asset { Id = 1, Url = "https://nihadfit.blob.core.windows.net/test/1.jpg" },
                new Asset { Id = 2, Url = "https://nihadfit.blob.core.windows.net/test/2.jpg" },
                new Asset { Id = 3, Url = "https://nihadfit.blob.core.windows.net/test/3.jpg" },
                new Asset { Id = 4, Url = "https://nihadfit.blob.core.windows.net/test/4.jpg" },
                new Asset { Id = 5, Url = "https://nihadfit.blob.core.windows.net/test/5.jpg" },
                new Asset { Id = 6, Url = "https://nihadfit.blob.core.windows.net/test/6.jpg" },
                new Asset { Id = 7, Url = "https://nihadfit.blob.core.windows.net/test/7.jpg" },
                new Asset { Id = 8, Url = "https://nihadfit.blob.core.windows.net/test/8.jpg" },
                new Asset { Id = 9, Url = "https://nihadfit.blob.core.windows.net/test/9.jpg" },
                new Asset { Id = 10, Url = "https://nihadfit.blob.core.windows.net/test/10.jpg" },
                new Asset { Id = 11, Url = "https://nihadfit.blob.core.windows.net/test/11.jpg" },
                new Asset { Id = 12, Url = "https://nihadfit.blob.core.windows.net/test/12.jpg" },
                new Asset { Id = 13, Url = "https://nihadfit.blob.core.windows.net/test/13.jpg" },
                new Asset { Id = 14, Url = "https://nihadfit.blob.core.windows.net/test/14.jpg" },
                new Asset { Id = 15, Url = "https://nihadfit.blob.core.windows.net/test/15.jpg" },
                new Asset { Id = 16, Url = "https://nihadfit.blob.core.windows.net/test/16.jpg" },
                new Asset { Id = 17, Url = "https://nihadfit.blob.core.windows.net/test/17.jpg" },
                new Asset { Id = 18, Url = "https://nihadfit.blob.core.windows.net/test/18.jpg" },
                new Asset { Id = 19, Url = "https://nihadfit.blob.core.windows.net/test/19.jpg" },
                new Asset { Id = 20, Url = "https://nihadfit.blob.core.windows.net/test/20.jpg" },                
                new Asset { Id = 21, Url = "https://nihadfit.blob.core.windows.net/test/21.jpg" },
                new Asset { Id = 22, Url = "https://nihadfit.blob.core.windows.net/test/22.jpg" },
                new Asset { Id = 23, Url = "https://nihadfit.blob.core.windows.net/test/23.jpg" },
                new Asset { Id = 24, Url = "https://nihadfit.blob.core.windows.net/test/24.jpg" },
                new Asset { Id = 25, Url = "https://nihadfit.blob.core.windows.net/test/25.jpg" },
                new Asset { Id = 26, Url = "https://nihadfit.blob.core.windows.net/test/26.jpg" },
                new Asset { Id = 27, Url = "https://nihadfit.blob.core.windows.net/test/27.jpg" },
                new Asset { Id = 28, Url = "https://nihadfit.blob.core.windows.net/test/28.jpg" },
                new Asset { Id = 29, Url = "https://nihadfit.blob.core.windows.net/test/29.jpg" },
                new Asset { Id = 30, Url = "https://nihadfit.blob.core.windows.net/test/30.jpg" },
                new Asset { Id = 31, Url = "https://nihadfit.blob.core.windows.net/test/31.jpg" },
                new Asset { Id = 32, Url = "https://nihadfit.blob.core.windows.net/test/32.jpg" },
                new Asset { Id = 33, Url = "https://nihadfit.blob.core.windows.net/test/33.jpg" },
                new Asset { Id = 34, Url = "https://nihadfit.blob.core.windows.net/test/34.jpg" },
                new Asset { Id = 35, Url = "https://nihadfit.blob.core.windows.net/test/35.jpg" },
                new Asset { Id = 36, Url = "https://nihadfit.blob.core.windows.net/test/36.jpg" },
                new Asset { Id = 37, Url = "https://nihadfit.blob.core.windows.net/test/37.jpg" },
                new Asset { Id = 38, Url = "https://nihadfit.blob.core.windows.net/test/38.jpg" },
                new Asset { Id = 39, Url = "https://nihadfit.blob.core.windows.net/test/39.jpg" },
                new Asset { Id = 40, Url = "https://nihadfit.blob.core.windows.net/test/40.jpg" }
            );
        }
    }
}
