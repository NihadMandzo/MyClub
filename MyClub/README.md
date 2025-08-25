# MyClub - Aplikacija za upravljanje sportskim klubom

MyClub je aplikacija za upravljanje sportskim klubom koja omogućava korisnicima da pregledaju i kupuju proizvode, prate utakmice, kupuju karte i upravljaju svojim članstvima. Aplikacija je izgrađena koristeći .NET Web API za backend, sa desktop i mobile aplikacijama rađenim u Flutteru.

## Kako pokrenuti projekat

### Priprema okruženja

1. **Raspakujte MyClub_env.zip**
   - Raspakujte fajl `env_file.zip` (šifra:fit)
   - Kopirajte `.env` fajl u root MyClub folder (na istom nivou kao docker-compose.yml)

2. **Pokretanje backend servisa**
   ```bash
   docker compose up
   ```

3. **Raspakovanje desktop i mobile aplikacija**
   - Raspakujte `fit-build-2025-25-08.zip`
   - Navigirajte do `.apk` fajla za Android mobilnu aplikaciju
   - Navigirajte do `.exe` fajla za desktop Windows aplikaciju

### Instaliranje aplikacija

- **Desktop aplikacija**: Pokrenite `.exe` fajl
- **Mobile aplikacija**: Instalirajte `.apk` fajl na Android uređaj

## Kredencijali za prijavljivanje

### Desktop aplikacija
- **Korisničko ime**: admin
- **Lozinka**: test

### Mobile aplikacija (Administrator)
- **Korisničko ime**: admin
- **Lozinka**: test

### Mobile aplikacija (Obični korisnici)
- **Korisničko ime**: user
- **Lozinka**: test

ili

- **Korisničko ime**: nihad123
- **Lozinka**: test

## Test kredencijali za plaćanje

### PayPal test nalog
Za testiranje kupovine karata, članstava i narudžbi koristite:
- **Email**: sb-43ieux45361356@personal.example.com
- **Lozinka**: Test1234

### Stripe test kartice
Za testiranje Stripe plaćanja posjetite: https://docs.stripe.com/testing
Na ovoj stranici možete pronaći različite test kartice za različite scenarije testiranja.

## RabbitMQ

Projekat koristi RabbitMQ za slanje informacija o narudžbama i za funkcionalnost zaboravljene lozinke.
