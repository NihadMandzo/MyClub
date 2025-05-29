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
                    Name = "Red",
                    HexCode = "#FF0000"
                },
                new Color
                {
                    Id = 2,
                    Name = "Blue",
                    HexCode = "#0000FF"
                },
                new Color
                {
                    Id = 3,
                    Name = "Green",
                    HexCode = "#00FF00"
                },
                new Color
                {
                    Id = 4,
                    Name = "Yellow",
                    HexCode = "#FFFF00"
                },
                new Color
                {
                    Id = 5,
                    Name = "Black",
                    HexCode = "#000000"
                },
                new Color
                {
                    Id = 6,
                    Name = "White",
                    HexCode = "#FFFFFF"
                },
                new Color
                {
                    Id = 7,
                    Name = "Purple",
                    HexCode = "#800080"
                },
                new Color
                {
                    Id = 8,
                    Name = "Orange",
                    HexCode = "#FFA500"
                },
                new Color
                {
                    Id = 9,
                    Name = "Grey",
                    HexCode = "#808080"
                },
                new Color
                {
                    Id = 10,
                    Name = "Brown",
                    HexCode = "#A52A2A"
                }
            );
        }
    }
} 