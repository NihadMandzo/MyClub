using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class ColorSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Color> entity)
        {
            entity.HasData(
                new Color
                {
                    Id = 1,
                    Name = "Bijela",
                    HexCode = "#FFFFFF"
                },
                new Color
                {
                    Id = 2,
                    Name = "Plava",
                    HexCode = "#0000FF"
                },
                new Color
                {
                    Id = 3,
                    Name = "Crna",
                    HexCode = "#000000"
                },
                new Color
                {
                    Id = 4,
                    Name = "Teget plava",
                    HexCode = "#071330"
                },
                new Color
                {
                    Id = 5,
                    Name = "Roza",
                    HexCode = "#F4C2C2"
                },
                new Color
                {
                    Id = 6,
                    Name = "Siva",
                    HexCode = "#808080"
                },
                new Color
                {
                    Id = 7,
                    Name = "Zelena",
                    HexCode = "#008000"
                }
            );
        }
    }
} 