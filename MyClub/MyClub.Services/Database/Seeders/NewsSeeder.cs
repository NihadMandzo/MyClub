using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class NewsSeeder
    {
        public static void SeedData(this EntityTypeBuilder<News> entity)
        {            entity.HasData(
                new News
                {                    Id = 1,
                    Title = "Historijska pobjeda na domaćem terenu protiv aktuelnog prvaka Evrope",
                    Content = "Naš klub je ostvario historijsku pobjedu na domaćem terenu protiv aktuelnog evropskog prvaka u prepunom stadionu. Utakmica je završila rezultatom 3-0, pokazujući nevjerovatnu dominaciju i kvalitet naše ekipe. Preko 30.000 navijača svjedočilo je maestralnoj izvedbi naših igrača, koji su od prve minute pokazali zašto se ovaj klub smatra jednim od najbrže rastućih u evropskom fudbalu. Posebno se istakao naš mladi veznjak svojim brilliant potezima i asistencijama, dok je odbrana djelovala neprobojno tokom svih 90 minuta. Ova pobjeda nam otvara put ka novim evropskim uspjesima.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 31, 12, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 2,
                    Title = "Spektakularni novi dresovi predstavljeni pred punim stadionom uz svjetlosni show",
                    Content = "Sa velikim ponosom predstavljamo revolucionarni dizajn dresova za predstojeću sezonu, koji su sinoć premijerno prikazani u spektakularnom ambijentu našeg stadiona. Novi dresovi predstavljaju perfektnu fuziju tradicije i modernog dizajna, izrađeni od najsavremenijih materijala koji garantuju maksimalnu udobnost igračima. Posebna pažnja posvećena je detaljima koji odražavaju bogatu historiju kluba - zlatni vez na kragni predstavlja godine osvajanja trofeja, dok suptilni pattern na dresu simbolizira arhitekturu našeg voljenog stadiona. Dresovi su izrađeni od 100% recikliranih materijala, čime klub pokazuje svoju posvećenost održivom razvoju.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 30, 15, 30, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 3,
                    Title = "Međunarodni omladinski kamp okupio mlade talente iz dvadeset zemalja svijeta",
                    Content = "Proteklog vikenda uspješno je završen najveći međunarodni omladinski kamp u historiji našeg kluba. Preko 200 mladih talenata iz 20 zemalja svijeta imalo je jedinstvenu priliku da trenira pod vodstvom naših UEFA Pro licenciranih trenera. Posebno nas raduje činjenica da su kampovi održani na potpuno renoviranim terenima našeg trening centra. Program je uključivao napredne tehnike treninga, analizu taktike, nutricionističke radionice i mentalne pripreme. Nekoliko izuzetnih talenata već je dobilo poziv da se pridruži našoj akademiji, čime nastavljamo tradiciju razvoja mladih igrača svjetske klase.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 29, 9, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 4,
                    Title = "Slavni evropski stručnjak sa tri Lige Prvaka preuzima kormilo kluba",
                    Content = "S velikim zadovoljstvom i ponosom objavljujemo dolazak novog šefa stručnog štaba, trostrukog osvajača Lige Prvaka i jednog od najcjenjenijih trenera današnjice. Nakon intenzivnih pregovora, uspjeli smo osigurati njegovo vođstvo za naredne tri sezone. Njegov impresivan CV uključuje osvajanje najvećih evropskih liga, razvoj brojnih mladih talenata u svjetske zvijezde, te implementaciju modernog, atraktivnog stila igre. Novi trener je već predstavio detaljan plan razvoja kluba koji uključuje značajna ulaganja u infrastrukturu, akademiju i prvi tim.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 28, 14, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 5,
                    Title = "Multimilionska renovacija stadiona donosi revolucionarne promjene u svijetu fudbala",
                    Content = "Radovi na sveobuhvatnoj renovaciji našeg stadiona napreduju iznad svih očekivanja. Projekat vrijedan 150 miliona eura uključuje instalaciju najmodernije LED rasvjete, potpuno novi sistem grijanja terena, proširenje kapaciteta na 45.000 sjedećih mjesta i izgradnju ekskluzivne VIP zone. Posebno smo ponosni na implementaciju revolucionarnog sistema za praćenje lopte i igrača u realnom vremenu, prvi takve vrste u Evropi. Novi ekrani ultra visoke rezolucije i vrhunski audio sistem osigurat će nezaboravan doživljaj za sve posjetioce.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 27, 11, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 6,
                    Title = "Međunarodni humanitarni turnir okuplja najveće svjetske klubove za pomoć djeci",
                    Content = "Ovog vikenda naš klub organizuje prestižni međunarodni humanitarni turnir koji će okupiti najveće evropske klubove. Sav prihod od prodaje ulaznica i marketinških aktivnosti bit će usmjeren za izgradnju novog rehabilitacijskog centra za djecu sa posebnim potrebama. Turnir će trajati tri dana i uključivat će nastupe svjetski poznatih muzičara između utakmica. Posebno nas raduje što su se odazvali brojni bivši igrači našeg kluba koji će odigrati revijalne utakmice. Očekujemo rekordnu posjetu i prikupljanje preko milion eura za ovu plemenitu svrhu.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 26, 10, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 7,
                    Title = "Revolucionarni blockchain sistem za prodaju karata uvodi nove standarde",
                    Content = "Od danas predstavljamo potpuno novi, revolucionarni sistem za kupovinu i upravljanje ulaznicama baziran na blockchain tehnologiji. Ovaj inovativni sistem, razvijen u saradnji sa vodećim tehnološkim kompanijama, omogućava trenutnu kupovinu, siguran transfer i potpunu eliminaciju falsifikovanih ulaznica. Svaka ulaznica je jedinstveni NFT token koji navijačima pruža dodatne pogodnosti, uključujući ekskluzivni digitalni sadržaj, posebne popuste u klupskim prodavnicama i mogućnost skupljanja digitalnih suvenira. Sistem također uključuje naprednu mobilnu aplikaciju sa proširenom stvarnošću za pronalaženje sjedišta i navigaciju kroz stadion.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 25, 9, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 8,
                    Title = "Povijesni početak sezone sa tri dominantne pobjede i bez primljenog gola",
                    Content = "Nakon prva tri kola nove sezone, naš tim pokazuje nezapamćenu dominaciju koja oduševljava fudbalske stručnjake širom Evrope. Sa tri uvjerljive pobjede i impresivnom gol razlikom 12:0, postavljamo nove standarde u ligaškom takmičenju. Posebno impresionira činjenica da smo prvi tim u historiji lige koji nije primio gol u prva tri kola, uz prosječan posjed lopte od 73%. Statistike pokazuju da je naš tim kreirao preko 25 izglednih šansi po utakmici, što je najviše u top 5 evropskih liga. Analitičari posebno ističu našu presing igru i brze transformacije koje su postale zaštitni znak novog stručnog štaba.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 24, 18, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 9,
                    Title = "Rekordni sponzorski ugovori sa vodećim svjetskim brendovima mijenjaju budućnost kluba",
                    Content = "Danas je naš klub potpisao historijske sponzorske ugovore sa pet vodećih svjetskih kompanija, čija ukupna vrijednost prelazi 300 miliona eura. Ova strateška partnerstva uključuju vodeće tehnološke kompanije, proizvođače sportske opreme i globalne brendove iz automobilske industrije. Posebno je značajan desetogodišnji ugovor koji uključuje imenovanje našeg stadiona i revolucionarnu tehnološku integraciju koja će navijačima pružiti potpuno novo iskustvo praćenja utakmica. Dio sredstava bit će usmjeren u razvoj mladih talenata, unapređenje infrastrukture i programe društvene odgovornosti.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 23, 13, 0, 0, DateTimeKind.Utc)
                },
                new News
                {                    Id = 10,
                    Title = "Nova međunarodna fudbalska akademija sa revolucionarnim pristupom razvoju mladih talenata",
                    Content = "Sa ponosom najavljujemo otvaranje naše nove međunarodne fudbalske akademije, projekta vrijednog 50 miliona eura koji će postaviti nove standarde u razvoju mladih talenata. Akademija će koristiti najmoderniju tehnologiju uključujući AI analizu pokreta, personalizirane programe treninga i virtualnu realnost za taktičku pripremu. Osigurali smo saradnju sa vodećim svjetskim stručnjacima iz oblasti sportske medicine, psihologije i nutricionizma. Program će biti dostupan djeci uzrasta 5-18 godina, sa posebnim stipendijskim programom za talentovane igrače iz cijelog svijeta. Akademija uključuje i internacionalni obrazovni program akreditovan od strane vodećih svjetskih univerziteta.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 22, 11, 0, 0, DateTimeKind.Utc)
                }
            );
        }
    }
}
