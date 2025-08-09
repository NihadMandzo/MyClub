using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System.Security.Cryptography;
using System.Text;

namespace MyClub.Services.Database.Seeders;

public static class UserSeeder
{
    public static void SeedData(this EntityTypeBuilder<User> entity)
    {
        // Generate password hash and salt for admin
        string adminSalt;
        string adminHash = HashPassword("admin123", out adminSalt);

        // Generate password hash and salt for user
        string userSalt;
        string userHash = HashPassword("user123", out userSalt);

        // Generate password hash and salt for user1
        string user1Salt;
        string user1Hash = HashPassword("nihad123", out user1Salt);
       
        entity.HasData(
            new User {  
                Id = 1, 
                FirstName = "Admin", 
                LastName = "Admin", 
                Email = "admin@myclub.com", 
                Username = "admin",
                PasswordHash = adminHash, 
                PasswordSalt = adminSalt,
                RoleId = 1 
            },
            new User { 
                Id = 2, 
                FirstName = "User", 
                LastName = "User", 
                Email = "user@myclub.com", 
                Username = "user",
                PasswordHash = userHash, 
                PasswordSalt = userSalt,
                RoleId = 2 
            },
            new User { 
                Id = 3, 
                FirstName = "Nihad", 
                LastName = "Kurtic", 
                Email = "nihad.mandzo@bosnjackagim.edu.ba", 
                Username = "nihad123",
                PasswordHash = user1Hash, 
                PasswordSalt = user1Salt,
                RoleId = 2 
            }
        );
    }

    private static string HashPassword(string password, out string salt)
    {
        // Generate a salt
        using (var rng = new RNGCryptoServiceProvider())
        {
            byte[] saltBytes = new byte[16];
            rng.GetBytes(saltBytes);
            salt = Convert.ToBase64String(saltBytes);
        }

        // Hash the password with the salt
        using (var deriveBytes = new Rfc2898DeriveBytes(password, Convert.FromBase64String(salt), 10000))
        {
            byte[] hash = deriveBytes.GetBytes(20); // 20 bytes for the hash
            return Convert.ToBase64String(hash);
        }
    }
}
