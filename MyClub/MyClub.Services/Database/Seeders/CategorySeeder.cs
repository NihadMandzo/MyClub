using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class CategorySeeder
    {
        public static void SeedData(this EntityTypeBuilder<Category> entity)
        {
            entity.HasData(
                new Category
                {
                    Id = 1,
                    Name = "Jerseys",
                    Description = "Official team jerseys",
                    IsActive = true
                },
                new Category
                {
                    Id = 2,
                    Name = "T-Shirts",
                    Description = "Casual t-shirts with club logos",
                    IsActive = true
                },
                new Category
                {
                    Id = 3,
                    Name = "Hoodies",
                    Description = "Sweatshirts and hoodies",
                    IsActive = true
                },
                new Category
                {
                    Id = 4,
                    Name = "Pants",
                    Description = "Training and casual pants",
                    IsActive = true
                },
                new Category
                {
                    Id = 5,
                    Name = "Shorts",
                    Description = "Sports and casual shorts",
                    IsActive = true
                },
                new Category
                {
                    Id = 6,
                    Name = "Jackets",
                    Description = "Outdoor and training jackets",
                    IsActive = true
                },
                new Category
                {
                    Id = 7,
                    Name = "Accessories",
                    Description = "Scarves, hats, and other accessories",
                    IsActive = true
                },
                new Category
                {
                    Id = 8,
                    Name = "Footwear",
                    Description = "Shoes and boots",
                    IsActive = true
                },
                new Category
                {
                    Id = 9,
                    Name = "Equipment",
                    Description = "Balls, bags, and training equipment",
                    IsActive = true
                },
                new Category
                {
                    Id = 10,
                    Name = "Memorabilia",
                    Description = "Collectibles and souvenirs",
                    IsActive = true
                }
            );
        }
    }
} 