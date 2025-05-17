using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.Text;

namespace MyClub.Services
{
    public class UserService : IUserService
    {
        private readonly MyClubContext _context;

        public UserService(MyClubContext context)
        {
            _context = context;
        }

        public async Task<List<UserResponse>> Get(UserSearchObject search)
        {
            var query = _context.Users.AsQueryable();

            // Apply filters based on search parameters
            if (!string.IsNullOrWhiteSpace(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrWhiteSpace(search.FirstName))
                query = query.Where(u => u.FirstName.Contains(search.FirstName));

            if (!string.IsNullOrWhiteSpace(search.LastName))
                query = query.Where(u => u.LastName.Contains(search.LastName));

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            // Full-Text Search across multiple fields
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(u => 
                    u.FirstName.Contains(search.FTS) || 
                    u.LastName.Contains(search.FTS) || 
                    u.Username.Contains(search.FTS) || 
                    u.Email.Contains(search.FTS));
            }

            var users = await query.ToListAsync();
            return users.Select(MapToResponse).ToList();
        }

        public async Task<List<UserResponse>> GetAllAsync()
        {
            var users = await _context.Users.ToListAsync();
            return users.Select(MapToResponse).ToList();
        }

        public async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            return user != null ? MapToResponse(user) : null;
        }

        public async Task<UserResponse> CreateAsync(UserUpsertRequest request)
        {
            // Check for duplicate email and username
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new InvalidOperationException("Email is already in use");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new InvalidOperationException("Username is already taken");

            // Create new user entity
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            // Hash password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                string salt;
                user.PasswordHash = HashPassword(request.Password, out salt);
                user.PasswordSalt = salt;
            }

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            return MapToResponse(user);
        }

        public async Task<UserResponse?> UpdateAsync(int id, UserUpsertRequest request)
        {
            var existingUser = await _context.Users.FindAsync(id);
            
            if (existingUser == null)
                return null;

            // Check for duplicate email and username, excluding the current user
            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
                throw new InvalidOperationException("Email is already in use");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
                throw new InvalidOperationException("Username is already taken");

            // Update properties
            existingUser.FirstName = request.FirstName;
            existingUser.LastName = request.LastName;
            existingUser.Email = request.Email;
            existingUser.Username = request.Username;
            existingUser.PhoneNumber = request.PhoneNumber;
            existingUser.IsActive = request.IsActive;
            
            // Update password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                string salt;
                existingUser.PasswordHash = HashPassword(request.Password, out salt);
                existingUser.PasswordSalt = salt;
            }

            await _context.SaveChangesAsync();
            return MapToResponse(existingUser);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return false;

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return true;
        }

        // Helper methods
        private UserResponse MapToResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.Username,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                IsActive = user.IsActive,
                CreatedAt = user.CreatedAt,
                LastLogin = user.LastLogin
            };
        }

        private string HashPassword(string password, out string salt)
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

        private bool VerifyPassword(string password, string salt, string hashedPassword)
        {
            using (var deriveBytes = new Rfc2898DeriveBytes(password, Convert.FromBase64String(salt), 10000))
            {
                byte[] hash = deriveBytes.GetBytes(20);
                return Convert.ToBase64String(hash) == hashedPassword;
            }
        }
    }
}