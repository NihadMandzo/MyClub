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
                },
                new News
                {
                    Id = 11,
                    Title = "Revolucija u analizi podataka: Kako AI mijenja sportsku industriju",
                    Content = "U posljednjih nekoliko godina, umjetna inteligencija (AI) je postala ključni faktor u analizi podataka u sportu. Naši analitičari koriste napredne AI alate za obradu velikih količina podataka, što nam omogućava da bolje razumijemo performanse igrača i timsku dinamiku. Ova tehnologija ne samo da poboljšava naše strategije, već i pruža navijačima dublji uvid u igru. U narednim mjesecima planiramo implementirati još sofisticiranije AI modele koji će dodatno unaprijediti naše analitičke sposobnosti.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 21, 10, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 12,
                    Title = "Inovacije u sportskom marketingu: Kako privući mlađu publiku",
                    Content = "U svijetu sportskog marketinga, privlačenje mlađe publike postaje sve veći izazov. Naš tim stručnjaka razvija nove strategije koje uključuju korištenje društvenih mreža, influencera i interaktivnog sadržaja kako bi se povezali s ovom demografskom grupom. Planiramo organizirati seriju događaja i kampanja koje će uključivati popularne video igre, e-sport i druge oblike zabave koji su privlačni mladima. Naš cilj je stvoriti zajednicu koja će uključivati mlade navijače i omogućiti im da postanu aktivni sudionici u životu kluba.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 20, 9, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 13,
                    Title = "Održivi razvoj u sportu: Naš put ka ekološkoj odgovornosti",
                    Content = "Kao klub, posvećeni smo održivom razvoju i smanjenju našeg ekološkog otiska. U posljednjih godinu dana implementirali smo niz mjera koje uključuju korištenje solarnih panela na stadionu, reciklažu svih materijala i smanjenje potrošnje plastike. Također, planiramo pokrenuti edukativne programe za naše navijače o važnosti očuvanja okoliša. Naš cilj je postati lider u sportskom sektoru kada je riječ o ekološkoj odgovornosti.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 19, 8, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 14,
                    Title = "Tehnologija u sportu: Kako AI mijenja igru",
                    Content = "Umjetna inteligencija (AI) postaje sve prisutnija u sportu, od analize performansi igrača do unapređenja iskustva navijača. Naš tim istražuje kako AI može pomoći u donošenju boljih odluka na terenu, kao i u optimizaciji treninga. Također, planiramo implementirati AI rješenja koja će poboljšati interakciju s navijačima putem personaliziranih sadržaja i preporuka.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 18, 7, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 15,
                    Title = "E-sport i fudbal: Nova era sportskog natjecanja",
                    Content = "E-sport postaje sve popularniji, a naš klub prepoznaje njegov potencijal. Planiramo organizirati seriju e-sport turnira koji će uključivati popularne fudbalske video igre. Ovi događaji ne samo da će privući mlađu publiku, već će i omogućiti našim igračima da pokažu svoje vještine u digitalnom svijetu. Također, istražujemo mogućnosti suradnje s profesionalnim e-sport timovima kako bismo unaprijedili naše znanje i iskustvo u ovom području.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 17, 6, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 16,
                    Title = "Globalizacija sporta: Kako povezati navijače širom svijeta",
                    Content = "U današnjem globaliziranom svijetu, povezivanje s navijačima postaje sve važnije. Naš klub planira proširiti svoju prisutnost na međunarodnoj sceni kroz seriju prijateljskih utakmica u različitim zemljama, kao i putem digitalnih platformi koje omogućavaju interakciju s navijačima iz cijelog svijeta. Također, istražujemo mogućnosti suradnje s klubovima iz drugih zemalja kako bismo razmijenili iskustva i unaprijedili naš rad.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 16, 5, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 17,
                    Title = "Fudbalska akademija: Naš fokus na razvoj mladih talenata",
                    Content = "Naša fudbalska akademija nastavlja s radom na razvoju mladih talenata. Ove godine planiramo otvoriti nove trening centre u različitim regijama, što će omogućiti djeci iz cijele zemlje da se pridruže našim programima. Također, surađujemo s lokalnim školama i sportskim klubovima kako bismo identificirali i razvili mlade talente. Naš cilj je stvoriti sljedeću generaciju vrhunskih fudbalera koji će predstavljati naš klub na najvišoj razini.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 15, 4, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 18,
                    Title = "Inovacije u sportskom marketingu: Kako privući mlađu publiku",
                    Content = "U svijetu sportskog marketinga, privlačenje mlađe publike postaje sve veći izazov. Naš tim stručnjaka razvija nove strategije koje uključuju korištenje društvenih mreža, influencera i interaktivnog sadržaja kako bi se povezali s ovom demografskom grupom. Planiramo organizirati seriju događaja i kampanja koje će uključivati popularne video igre, e-sport i druge oblike zabave koji su privlačni mladima. Naš cilj je stvoriti zajednicu koja će uključivati mlade navijače i omogućiti im da postanu aktivni sudionici u životu kluba.",      
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 14, 3, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 19,
                    Title = "Održivi razvoj u sportu: Naš put ka ekološkoj odgovornosti",
                    Content = "Kao klub, posvećeni smo održivom razvoju i smanjenju našeg ekološkog otiska. U posljednjih godinu dana implementirali smo niz mjera koje uključuju korištenje solarnih panela na stadionu, reciklažu svih materijala i smanjenje potrošnje plastike. Također, planiramo pokrenuti edukativne programe za naše navijače o važnosti očuvanja okoliša. Naš cilj je postati lider u sportskom sektoru kada je riječ o ekološkoj odgovornosti.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 13, 2, 0, 0, DateTimeKind.Utc)
                },
                new News
                {
                    Id = 20,
                    Title = "Tehnologija u sportu: Kako AI mijenja igru",
                    Content = "Umjetna inteligencija (AI) postaje sve prisutnija u sportu, od analize performansi igrača do unapređenja iskustva navijača. Naš tim istražuje kako AI može pomoći u donošenju boljih odluka na terenu, kao i u optimizaciji treninga. Također, planiramo implementirati AI rješenja koja će poboljšati interakciju s navijačima putem personaliziranih sadržaja i preporuka.",
                    UserId = 1,
                    CreatedAt = new DateTime(2025, 5, 12, 1, 0, 0, DateTimeKind.Utc)
                }
            );
        }
    }
}
