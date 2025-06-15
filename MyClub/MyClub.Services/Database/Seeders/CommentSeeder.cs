using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;

namespace MyClub.Services.Database.Seeders
{
    public static class CommentSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Comment> entity)
        {
            entity.HasData(
                // Comments for the first news (Velika pobjeda na domaćem terenu)
                new Comment
                {
                    Id = 1,
                    Content = "Nevjerovatna utakmica! Čestitke cijelom timu na izvanrednoj igri!",
                    CreatedAt = new DateTime(2025, 5, 31, 14, 0, 0, DateTimeKind.Utc),
                    NewsId = 1,
                    UserId = 2
                },
                new Comment
                {
                    Id = 2,
                    Content = "Atmosfera je bila fenomenalna, navijači su bili sjajni.",
                    CreatedAt = new DateTime(2025, 5, 31, 14, 30, 0, DateTimeKind.Utc),
                    NewsId = 1,
                    UserId = 3
                },
                new Comment
                {
                    Id = 3,
                    Content = "Odbrana je bila kao zid! Sjajan posao momci!",
                    CreatedAt = new DateTime(2025, 5, 31, 15, 0, 0, DateTimeKind.Utc),
                    NewsId = 1,
                    UserId = 3
                },

                // Comments for the second news (Novi dresovi za novu sezonu)
                new Comment
                {
                    Id = 4,
                    Content = "Dresovi izgledaju fantastično! Jedva čekam da nabavim svoj.",
                    CreatedAt = new DateTime(2025, 5, 30, 16, 0, 0, DateTimeKind.Utc),
                    NewsId = 2,
                    UserId = 2
                },
                new Comment
                {
                    Id = 5,
                    Content = "Dizajn je savršen, spoj tradicije i modernog.",
                    CreatedAt = new DateTime(2025, 5, 30, 16, 30, 0, DateTimeKind.Utc),
                    NewsId = 2,
                    UserId = 2
                }
            );
        }
    }
}
