using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class NewsSeeder
    {
        public static void SeedData(this EntityTypeBuilder<News> entity)
        {            entity.HasData(
                new News
                {
                    Id = 1,
                    Title = "Velika pobjeda na domaćem terenu",
                    Content = "Naš klub je ostvario značajnu pobjedu na domaćem terenu protiv jakog protivnika. Utakmica je završila rezultatom 3-0, pokazujući dominaciju i kvalitet naše ekipe.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 31, 12, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 2,
                    Title = "Novi dresovi za novu sezonu",
                    Content = "Sa ponosom predstavljamo nove dresove za predstojeću sezonu. Dizajn kombinuje tradicionalne boje kluba sa modernim elementima, održavajući naše bogato naslijeđe.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 30, 15, 30, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 3,
                    Title = "Uspješan omladinski kamp",
                    Content = "Proteklog vikenda održan je omladinski kamp našeg kluba. Preko 100 mladih talenata imalo je priliku trenirati sa našim trenerima i razvijati svoje vještine.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 29, 9, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 4,
                    Title = "Novi trener preuzima kormilo",
                    Content = "S velikim zadovoljstvom objavljujemo dolazak novog trenera koji će voditi naš tim u predstojećoj sezoni. Njegova bogata karijera i dokazani uspjesi obećavaju uzbudljivu budućnost za klub.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 28, 14, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 5,
                    Title = "Renovacija stadiona u punom jeku",
                    Content = "Radovi na renovaciji našeg stadiona napreduju prema planu. Nova rasvjeta, poboljšani tereni i modernizovane tribine će značajno unaprijediti doživljaj naših navijača.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 27, 11, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 6,
                    Title = "Humanitarni turnir za djecu",
                    Content = "Ovog vikenda organizujemo humanitarni turnir za pomoć djeci sa posebnim potrebama. Pozivamo sve članove kluba i navijače da se pridruže ovoj plemenitoj akciji.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 26, 10, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 7,
                    Title = "Novi sistem prodaje karata",
                    Content = "Od danas uvodimo novi online sistem za kupovinu karata koji će omogućiti navijačima lakšu i bržu kupovinu ulaznica za sve utakmice.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 25, 9, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 8,
                    Title = "Uspješan start sezone",
                    Content = "Nakon prve tri utakmice u sezoni, naš tim je pokazao izvanrednu formu sa sve tri pobjede i impresivnom gol razlikom od 8:1.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 24, 18, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 9,
                    Title = "Nova partnerstva za klub",
                    Content = "Potpisali smo nekoliko značajnih sponzorskih ugovora koji će osigurati stabilnu budućnost kluba i omogućiti dalja ulaganja u razvoj.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 23, 13, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 10,
                    Title = "Škola fudbala za najmlađe",
                    Content = "Otvaramo novu školu fudbala za djecu uzrasta od 5 do 12 godina. Treninzi će biti vođeni od strane naših iskusnih trenera sa UEFA licencama.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 22, 11, 0, 0, DateTimeKind.Utc)
                }
            );
        }
    }
}
