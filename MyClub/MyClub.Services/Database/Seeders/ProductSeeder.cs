using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class ProductSeeder
{
    public static void SeedData(this EntityTypeBuilder<Product> entity)
    {
            entity.HasData(
                new Product
                {
                    Id = 1,
                    Name = "Domaći Dres 2024/25",
                    Description = "Oficijelni domaći dres za sezonu 2024/25",
                    Price = 89.99m,
                    CategoryId = 1,
                    ColorId = 2,
                    BarCode = "1234567890123",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 2,
                    Name = "Gostujući Dres 2024/25",
                    Description = "Oficijelni gostujući dres za sezonu 2024/25",
                    Price = 89.99m,
                    CategoryId = 1,
                    ColorId = 1,
                    BarCode = "1234567890124",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 3,
                    Name = "Casual Majica Logo",
                    Description = "Pamučna majica sa velikim logom kluba",
                    Price = 29.99m,
                    CategoryId = 2,
                    ColorId = 3,
                    BarCode = "1234567890125",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 4,
                    Name = "Duks sa Kapuljačom",
                    Description = "Topli duks sa vezenim grbom kluba",
                    Price = 59.99m,
                    CategoryId = 3,
                    ColorId = 4,
                    BarCode = "1234567890126",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 5,
                    Name = "Trening Šorc",
                    Description = "Lagani šorc za trening",
                    Price = 34.99m,
                    CategoryId = 4,
                    ColorId = 3,
                    BarCode = "1234567890127",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 6,
                    Name = "Zimska Kapa",
                    Description = "Topla zimska kapa sa vezenim grbom",
                    Price = 24.99m,
                    CategoryId = 5,
                    ColorId = 2,
                    BarCode = "1234567890128",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 7,
                    Name = "Šal Ultras",
                    Description = "Navijački šal sa nazivom grupe",
                    Price = 19.99m,
                    CategoryId = 6,
                    ColorId = 4,
                    BarCode = "1234567890129",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 8,
                    Name = "Privjesak Grb",
                    Description = "Metalni privjesak sa grbom kluba",
                    Price = 9.99m,
                    CategoryId = 7,
                    ColorId = 6,
                    BarCode = "1234567890130",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 9,
                    Name = "Baby Set",
                    Description = "Set za bebe sa bodićem i čarapicama",
                    Price = 29.99m,
                    CategoryId = 8,
                    ColorId = 5,
                    BarCode = "1234567890131",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 10,
                    Name = "Velika Zastava",
                    Description = "Velika navijačka zastava sa grbom",
                    Price = 39.99m,
                    CategoryId = 9,
                    ColorId = 2,
                    BarCode = "1234567890132",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 11,
                    Name = "Retro Dres 1980",
                    Description = "Replika dresa iz 1980. godine",
                    Price = 79.99m,
                    CategoryId = 10,
                    ColorId = 4,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 12,
                    Name = "Treći Dres 2024/25",
                    Description = "Oficijelni treći dres za sezonu 2024/25",
                    Price = 89.99m,
                    CategoryId = 1,
                    ColorId = 7,
                    BarCode = "1234567890133",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 13,
                    Name = "Polo Majica",
                    Description = "Elegantna polo majica sa diskretnim grbom",
                    Price = 39.99m,
                    CategoryId = 2,
                    ColorId = 6,
                    BarCode = "1234567890134",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 14,
                    Name = "Dječiji Dres Set",
                    Description = "Set dresa i šorca za djecu",
                    Price = 69.99m,
                    CategoryId = 8,
                    ColorId = 2,
                    BarCode = "1234567890135",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Id = 15,
                    Name = "Zimska Jakna",
                    Description = "Topla zimska jakna sa kapuljačom",
                    Price = 129.99m,
                    CategoryId = 3,
                    ColorId = 3,
                    BarCode = "1234567890136",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                }
            );
        }
    }
}