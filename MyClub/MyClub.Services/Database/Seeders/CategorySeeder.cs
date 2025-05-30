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
                    Name = "Dresovi",
                    Description = "Oficijelni dresovi kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 2,
                    Name = "Majice",
                    Description = "Casual majice kluba ",
                    IsActive = true
                },
                new Category
                {
                    Id = 3,
                    Name = "Dukserice",
                    Description = "Dukserice kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 4,
                    Name = "Šorcevi",
                    Description = "Šorcevi kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 5,
                    Name = "Kape",
                    Description = "Kape kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 6,
                    Name = "Šalovi",
                    Description = "Šalovi kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 7,
                    Name = "Aksesoari",
                    Description = "Aksesoari kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 8,
                    Name = "Odjeca za bebe",
                    Description = "Odjeca za bebe kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 9,
                    Name = "Zastave",
                    Description = "Zastave kluba",
                    IsActive = true
                },
                new Category
                {
                    Id = 10,
                    Name = "Retro stil",
                    Description = "Retro stil kluba",
                    IsActive = true
                }
            );
        }
    }
} 