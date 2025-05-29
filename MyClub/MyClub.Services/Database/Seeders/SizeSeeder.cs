using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class SizeSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Size> entity)
        {
            entity.HasData(
                new Size
                {
                    Id = 1,
                    Name = "XXS"
                },
                new Size
                {
                    Id = 2,
                    Name = "XS"
                },
                new Size
                {
                    Id = 3,
                    Name = "S"
                },
                new Size
                {
                    Id = 4,
                    Name = "M"
                },
                new Size
                {
                    Id = 5,
                    Name = "L"
                },
                new Size
                {
                    Id = 6,
                    Name = "XL"
                },
                new Size
                {
                    Id = 7,
                    Name = "XXL"
                }
            );
        }
    }
} 