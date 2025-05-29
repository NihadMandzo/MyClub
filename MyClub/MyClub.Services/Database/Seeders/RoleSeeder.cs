using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders
{
    public static class RoleSeeder
    {
        public static void SeedData(this EntityTypeBuilder<Role> entity)
        {
            entity.HasData(
                new Role
                {
                    Id = 1,
                    Name = "Administrator"
                },
                new Role
                {
                    Id = 2,
                    Name = "User"
                }
            );
        }
    }
} 