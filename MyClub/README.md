# MyClub Database Seeders

This repository contains database seeders for the MyClub application. The seeders populate the database with initial data for colors, categories, sizes, and roles.

## Seeded Data

### Colors
- Red (#FF0000)
- Blue (#0000FF)
- Green (#00FF00)
- Yellow (#FFFF00)
- Black (#000000)
- White (#FFFFFF)
- Purple (#800080)
- Orange (#FFA500)
- Grey (#808080)
- Brown (#A52A2A)

### Categories
- Jerseys - Official team jerseys
- T-Shirts - Casual t-shirts with club logos
- Hoodies - Sweatshirts and hoodies
- Pants - Training and casual pants
- Shorts - Sports and casual shorts
- Jackets - Outdoor and training jackets
- Accessories - Scarves, hats, and other accessories
- Footwear - Shoes and boots
- Equipment - Balls, bags, and training equipment
- Memorabilia - Collectibles and souvenirs

### Sizes
- XS
- S
- M
- L
- XL
- XXL
- XXXL
- One Size
- 36
- 38
- 40
- 42
- 44

### Roles
- Administrator
- User

## How It Works

The database seeders are automatically applied during the Entity Framework model creation process. The data is seeded using the `HasData` method, which ensures that data is only added if it doesn't already exist in the database.

## Implementation

The seeders are organized in the following structure:

```
MyClub.Services
└── Database
    ├── DatabaseSeeder.cs (Extension method for ModelBuilder that calls all seeders)
    └── Seeders
        ├── RoleSeeder.cs
        ├── ColorSeeder.cs
        ├── SizeSeeder.cs
        └── CategorySeeder.cs
```

Each seeder follows the same pattern:
1. A static class with an extension method for EntityTypeBuilder
2. The extension method uses HasData to seed predefined entities
3. Each entity has a predefined ID to ensure consistency

The main DatabaseSeeder is called from the OnModelCreating method in MyClubContext.cs, ensuring that all seed data is applied when the database is created or migrated. 