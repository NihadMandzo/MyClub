using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class ClubSeeder
{
    public static void SeedData(this EntityTypeBuilder<Club> entity)
    {
        entity.HasData(
            new Club
            {
                Id = 1,
                Name = "Fudbalski Klub Foča",
                Description = "Fudbalski klub Foča, osnovan 1936. godine, predstavlja ponos grada na Drini i jedan je od najstarijih sportskih kolektiva u regiji. Kroz svoju bogatu historiju, klub je postao neraskidivi dio identiteta grada Foče, stvarajući nezaboravne trenutke na legendarnom stadionu 'Drinska Dolina'.\n\nKlub je svoj prvi značajniji uspjeh ostvario 1956. godine plasmanom u Republičku ligu BiH, gdje je proveo nekoliko uspješnih sezona. Šezdesete godine prošlog vijeka označile su zlatno doba kluba, kada je FK Foča postala prepoznatljiva po svom atraktivnom stilu igre i razvoju mladih talenata. U tom periodu, klub je dva puta osvojio Kup Republike, 1964. i 1968. godine.\n\nDevedesete godine donijele su nove izazove, ali i pokazale nevjerovatnu otpornost kluba. Nakon rata, FK Foča je bio jedan od prvih klubova koji je obnovio svoje aktivnosti, pokazujući snagu sporta u ujedinjavanju zajednice. Godine 1998. klub je osvojio Prvu ligu Republike Srpske, što predstavlja jedan od najvećih uspjeha u novijoj historiji.\n\nStadion 'Drinska Dolina', sa kapacitetom od 4.500 mjesta, postao je dom nezaboravnih fudbalskih večeri. Posebno se pamti utakmica iz 2002. godine protiv Borca iz Banjaluke, kada je pred prepunim tribinama FK Foča ostvarila historijsku pobjedu rezultatom 3:0.\n\nKlub je posebno ponosan na svoju omladinsku školu fudbala, kroz koju je prošlo preko 5.000 mladih igrača. Nekoliko bivših polaznika danas igra u vodećim evropskim ligama, uključujući i reprezentativce Bosne i Hercegovine. Tradicija razvoja mladih talenata nastavlja se i danas, sa preko 200 djece u različitim uzrasnim kategorijama.\n\nU sezoni 2024/25, FK Foča započinje novi chapter svoje bogate historije. Sa modernizovanim infrastrukturnim kapacitetima, profesionalnim stručnim štabom i jasnom vizijom razvoja, klub cilja povratak u sam vrh bh. fudbala. Poseban fokus stavljen je na dalji razvoj omladinske škole i jačanje veza sa lokalnom zajednicom kroz različite društveno odgovorne projekte.\n\nKlupske boje, plava i bijela, postale su simbol ponosa i pripadnosti, a navijačka grupa 'Plavi Vukovi', osnovana 1989. godine, već više od tri decenije vjerno prati klub na svim utakmicama, stvarajući nezaboravnu atmosferu na 'Drinskoj Dolini'.",
                LogoImageId = 73
            }
        );
    }
}
