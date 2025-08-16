using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class PlayerSeeder
{
    public static void SeedData(this EntityTypeBuilder<Player> entity)
    {
        entity.HasData(
            new Player
            {
                Id = 1,
                FirstName = "Mirza",
                LastName = "Hodžić",
                Number = 1,
                PositionId = 1,
                DateOfBirth = new DateTime(1998, 3, 15),
                CountryId = 1,
                Height = 188,
                Weight = 82,
                Biography = "Iskusni golman poznat po svojim odličnim refleksima i kontroli kaznenog prostora.",
                ClubId = 1,
                ImageId = 74
            },
            new Player
            {
                Id = 2,
                FirstName = "Amar",
                LastName = "Begić",
                Number = 2,
                PositionId = 2,
                DateOfBirth = new DateTime(1999, 6, 22),
                CountryId = 1,
                Height = 178,
                Weight = 72,
                Biography = "Dinamičan desni bek sa odličnom sposobnošću centaršuta i odbrambenom sviješću.",
                ClubId = 1,
                ImageId = 75
            },
            new Player
            {
                Id = 3,
                FirstName = "Emir",
                LastName = "Jusufović",
                Number = 4,
                PositionId = 3,
                DateOfBirth = new DateTime(1997, 8, 10),
                CountryId = 1,
                Height = 190,
                Weight = 85,
                Biography = "Snažan centralni branič sa odličnom igrom glavom i liderskim kvalitetama.",
                ClubId = 1,
                ImageId = 76
            },
            new Player
            {
                Id = 4,
                FirstName = "Kenan",
                LastName = "Mujić",
                Number = 5,
                PositionId = 2,
                DateOfBirth = new DateTime(1998, 11, 3),
                CountryId = 1,
                Height = 188,
                Weight = 83,
                Biography = "Pouzdan štoper poznat po taktičkom razumijevanju igre i dobrom pozicioniranju.",
                ClubId = 1,
                ImageId = 77
            },
            new Player
            {
                Id = 5,
                FirstName = "Armin",
                LastName = "Salihović",
                Number = 3,
                PositionId = 3,
                DateOfBirth = new DateTime(2000, 4, 18),
                CountryId = 1,
                Height = 176,
                Weight = 70,
                Biography = "Brzi lijevi bek sa napadačkim instinktom i dobrim centaršutom.",
                ClubId = 1,
                ImageId = 78
            },
            new Player
            {
                Id = 6,
                FirstName = "Samir",
                LastName = "Hadžić",
                Number = 6,
                PositionId = 4,
                DateOfBirth = new DateTime(1997, 2, 25),
                CountryId = 1,
                Height = 183,
                Weight = 78,
                Biography = "Vrijedan zadnji vezni sa odličnim tacklingom i pasovima.",
                ClubId = 1,
                ImageId = 79
            },
            new Player
            {
                Id = 7,
                FirstName = "Denis",
                LastName = "Mehmedović",
                Number = 8,
                PositionId = 4,
                DateOfBirth = new DateTime(1999, 7, 12),
                CountryId = 1,
                Height = 180,
                Weight = 75,
                Biography = "Kreativni vezni igrač sa odličnom vizijom i dugim pasovima.",
                ClubId = 1,
                ImageId = 80
            },
            new Player
            {
                Id = 8,
                FirstName = "Adnan",
                LastName = "Kovačević",
                Number = 10,
                PositionId = 4,
                DateOfBirth = new DateTime(1998, 9, 30),
                CountryId = 1,
                Height = 177,
                Weight = 72,
                Biography = "Talentovani playmaker sa izuzetnim dribllingom i kreativnošću.",
                ClubId = 1,
                ImageId = 81
            },
            new Player
            {
                Id = 9,
                FirstName = "Edin",
                LastName = "Ramić",
                Number = 7,
                PositionId = 5,
                DateOfBirth = new DateTime(2001, 5, 8),
                CountryId = 1,
                Height = 175,
                Weight = 68,
                Biography = "Brzo i vješto krilo poznato po driblingu i centrašutevima.",
                ClubId = 1,
                ImageId = 82
            },
            new Player
            {
                Id = 10,
                FirstName = "Amer",
                LastName = "Gušić",
                Number = 11,
                PositionId = 5,
                DateOfBirth = new DateTime(2000, 8, 15),
                CountryId = 1,
                Height = 176,
                Weight = 70,
                Biography = "Eksplozivno lijevo krilo sa odličnim šutom i driblingom.",
                ClubId = 1,
                ImageId = 83
            },
            new Player
            {
                Id = 11,
                FirstName = "Jasmin",
                LastName = "Demirović",
                Number = 9,
                PositionId = 6,
                DateOfBirth = new DateTime(1997, 12, 20),
                CountryId = 1,
                Height = 185,
                Weight = 80,
                Biography = "Klinički napadač sa snažnim završnim udarcem i igrom glavom.",
                ClubId = 1,
                ImageId = 84
            },
            new Player
            {
                Id = 12,
                FirstName = "Haris",
                LastName = "Bašić",
                Number = 12,
                PositionId = 1,
                DateOfBirth = new DateTime(2002, 1, 5),
                CountryId = 1,
                Height = 186,
                Weight = 80,
                Biography = "Perspektivni mladi golman sa odličnim refleksima.",
                ClubId = 1,
                ImageId = 85
            },
            new Player
            {
                Id = 13,
                FirstName = "Tarik",
                LastName = "Mahmutović",
                Number = 13,
                PositionId = 2,
                DateOfBirth = new DateTime(2000, 3, 28),
                CountryId = 1,
                Height = 187,
                Weight = 82,
                Biography = "Mladi odbrambeni igrač sa velikim potencijalom i snažnom fizičkom prisutnošću.",
                ClubId = 1,
                ImageId = 86
            },
            new Player
            {
                Id = 14,
                FirstName = "Nedim",
                LastName = "Selimović",
                Number = 14,
                PositionId = 3,
                DateOfBirth = new DateTime(2001, 6, 14),
                CountryId = 1,
                Height = 177,
                Weight = 71,
                Biography = "Versatilan odbrambeni igrač koji može igrati na više pozicija.",
                ClubId = 1,
                ImageId = 87
            },
            new Player
            {
                Id = 15,
                FirstName = "Almir",
                LastName = "Hasanović",
                Number = 15,
                PositionId = 3,
                DateOfBirth = new DateTime(1999, 9, 8),
                CountryId = 1,
                Height = 175,
                Weight = 69,
                Biography = "Tehnički potkovan lijevi bek sa dobrim ofanzivnim doprinosom.",
                ClubId = 1,
                ImageId = 88
            },
            new Player
            {
                Id = 16,
                FirstName = "Senad",
                LastName = "Đulić",
                Number = 16,
                PositionId = 4,
                DateOfBirth = new DateTime(1998, 4, 2),
                CountryId = 1,
                Height = 182,
                Weight = 77,
                Biography = "Snažan zadnji vezni sa dobrim dugim pasovima.",
                ClubId = 1,
                ImageId = 89
            },
            new Player
            {
                Id = 17,
                FirstName = "Adem",
                LastName = "Fazlić",
                Number = 17,
                PositionId = 4,
                DateOfBirth = new DateTime(2000, 11, 25),
                CountryId = 1,
                Height = 179,
                Weight = 73,
                Biography = "Tehnički vezni igrač sa odličnom kontrolom lopte.",
                ClubId = 1,
                ImageId = 90
            },
            new Player
            {
                Id = 18,
                FirstName = "Damir",
                LastName = "Softić",
                Number = 18,
                PositionId = 4,
                DateOfBirth = new DateTime(2001, 2, 17),
                CountryId = 1,
                Height = 176,
                Weight = 70,
                Biography = "Kreativni ofanzivni vezni sa dobrim šutom.",
                ClubId = 1,
                ImageId = 91
            },
            new Player
            {
                Id = 19,
                FirstName = "Eldin",
                LastName = "Karić",
                Number = 19,
                PositionId = 5,
                DateOfBirth = new DateTime(2002, 7, 30),
                CountryId = 1,
                Height = 174,
                Weight = 68,
                Biography = "Mlado talentovano krilo sa impresivnom brzinom i tehnikom.",
                ClubId = 1,
                ImageId = 92
            },
            new Player
            {
                Id = 20,
                FirstName = "Faruk",
                LastName = "Imamović",
                Number = 20,
                PositionId = 5,
                DateOfBirth = new DateTime(2001, 10, 12),
                CountryId = 1,
                Height = 175,
                Weight = 69,
                Biography = "Vješto krilo poznato po svom driblingu.",
                ClubId = 1,
                ImageId = 93
            },
            new Player
            {
                Id = 21,
                FirstName = "Ibrahim",
                LastName = "Alibegović",
                Number = 21,
                PositionId = 6,
                DateOfBirth = new DateTime(1999, 1, 8),
                CountryId = 1,
                Height = 183,
                Weight = 78,
                Biography = "Snažan napadač sa dobrim završnim udarcem.",
                ClubId = 1,
                ImageId = 94
            },
            new Player
            {
                Id = 22,
                FirstName = "Mensur",
                LastName = "Delić",
                Number = 22,
                PositionId = 2,
                DateOfBirth = new DateTime(1998, 5, 20),
                CountryId = 1,
                Height = 186,
                Weight = 81,
                Biography = "Iskusni odbrambeni igrač sa snažnom igrom glavom.",
                ClubId = 1,
                ImageId = 95
            },
            new Player
            {
                Id = 23,
                FirstName = "Belmin",
                LastName = "Kurtić",
                Number = 23,
                PositionId = 4,
                DateOfBirth = new DateTime(2000, 12, 5),
                CountryId = 1,
                Height = 178,
                Weight = 72,
                Biography = "Box-to-box vezni sa dobrom izdržljivošću i pasovima.",
                ClubId = 1,
                ImageId = 96
            },
            new Player
            {
                Id = 24,
                FirstName = "Kemal",
                LastName = "Pojskić",
                Number = 24,
                PositionId = 4,
                DateOfBirth = new DateTime(2002, 3, 22),
                CountryId = 1,
                Height = 177,
                Weight = 70,
                Biography = "Mladi playmaker sa odličnom vizijom i tehnikom.",
                ClubId = 1,
                ImageId = 97
            },
            new Player
            {
                Id = 25,
                FirstName = "Ismet",
                LastName = "Dedić",
                Number = 25,
                PositionId = 6,
                DateOfBirth = new DateTime(2001, 8, 9),
                CountryId = 1,
                Height = 182,
                Weight = 76,
                Biography = "Perspektivni mladi napadač sa dobrim kretanjem i završnicom.",
                ClubId = 1,
                ImageId = 98
            }
        );
    }
}
