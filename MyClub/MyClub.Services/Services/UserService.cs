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
using MapsterMapper;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using MyClub.Services.Helpers;
using Microsoft.AspNetCore.Http;

namespace MyClub.Services
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchObject, UserUpsertRequest, UserUpsertRequest, User>, IUserService  
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;
        private readonly IConfiguration _config;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public UserService(MyClubContext context, IMapper mapper, IConfiguration config, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
        }


        public override async Task<PagedResult<UserResponse>> GetAsync(UserSearchObject search)
        {
            var query = _context.Users.AsQueryable();

            // Apply filters based on search parameters
            query = ApplyFilter(query, search);

            int totalCount = 0;
            
            // Always get total count before pagination
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;
            
            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var users = await query.ToListAsync();
            
            // Create the paged result with enhanced pagination metadata
            return new PagedResult<UserResponse>
            {
                Data = users.Select(u => _mapper.Map<UserResponse>(u)).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {
            // Apply filters based on search parameters
            if (!string.IsNullOrWhiteSpace(search?.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search?.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrWhiteSpace(search?.FirstName))
                query = query.Where(u => u.FirstName.Contains(search.FirstName));

            if (!string.IsNullOrWhiteSpace(search?.LastName))
                query = query.Where(u => u.LastName.Contains(search.LastName));

            if (search?.IsActive.HasValue == true)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            // Full-Text Search across multiple fields
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(u => 
                    u.FirstName.ToLower().Contains(searchTerm) || 
                    u.LastName.ToLower().Contains(searchTerm) || 
                    u.Username.ToLower().Contains(searchTerm) || 
                    u.Email.ToLower().Contains(searchTerm));
            }

            return query;
        }

        public override async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await _context.Users
                .AsNoTracking()
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Id == id);
                
            return user != null ? _mapper.Map<UserResponse>(user) : null;
        }

        public override async Task<UserResponse> CreateAsync(UserUpsertRequest request)
        {
            // Create new user entity
            var user = new User();
            user = MapInsertToEntity(user, request);
            await BeforeInsert(user, request);
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            return _mapper.Map<UserResponse>(user);
        }

        protected override async Task BeforeInsert(User entity, UserUpsertRequest request)
        {
            // Validate request
            ValidateUserRequest(request);

            // Check for duplicate email and username
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new UserException("Email is already in use");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Username is already taken");

            // Set default values
            entity.CreatedAt = DateTime.UtcNow;
            entity.RoleId = request.RoleId ?? 1; // Default to regular user role if not specified

            // Hash password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                string salt;
                entity.PasswordHash = HashPassword(request.Password, out salt);
                entity.PasswordSalt = salt;
            }
            else
            {
                throw new UserException("Password is required");
            }
        }

        protected override User MapInsertToEntity(User entity, UserUpsertRequest request)
        {
            entity.FirstName = request.FirstName;
            entity.LastName = request.LastName;
            entity.Username = request.Username;
            entity.Email = request.Email;
            entity.PhoneNumber = request.PhoneNumber;
            entity.IsActive = request.IsActive;
            
            return entity;
        }

        public override async Task<UserResponse> UpdateAsync(int id, UserUpsertRequest request)
        {
            var existingUser = await _context.Users.FindAsync(id);
            
            if (existingUser == null)
                throw new UserException("User not found");

            existingUser = MapUpdateToEntity(existingUser, request);
            await BeforeUpdate(existingUser, request);
            
            await _context.SaveChangesAsync();
            return _mapper.Map<UserResponse>(existingUser);
        }

        protected override async Task BeforeUpdate(User entity, UserUpsertRequest request)
        {
            // Validate request
            ValidateUserRequest(request);

            // Check for duplicate email and username, excluding the current user
            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != entity.Id))
                throw new UserException("Email is already in use");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username && u.Id != entity.Id))
                throw new UserException("Username is already taken");
                
            // Update password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                string salt;
                entity.PasswordHash = HashPassword(request.Password, out salt);
                entity.PasswordSalt = salt;
            }
        }

        protected override User MapUpdateToEntity(User entity, UserUpsertRequest request)
        {
            entity.FirstName = request.FirstName;
            entity.LastName = request.LastName;
            entity.Email = request.Email;
            entity.Username = request.Username;
            entity.PhoneNumber = request.PhoneNumber;
            entity.IsActive = request.IsActive;
            entity.RoleId = request.RoleId ?? entity.RoleId;
            
            return entity;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new UserException("User not found");

            await BeforeDelete(user);
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return true;
        }

        protected override async Task BeforeDelete(User entity)
        {
            // Check if this is the last administrator
            if (entity.RoleId == 1) // Assuming 1 is admin role ID
            {
                int adminCount = await _context.Users.CountAsync(u => u.RoleId == 1);
                if (adminCount <= 1)
                {
                    throw new UserException("Cannot delete the last administrator account");
                }
            }

            // Additional logic before deleting a user can be added here
            await Task.CompletedTask;
        }

        public async Task<bool> ChangePasswordAsync(ChangePasswordRequest request)
        {
            // Validate request
            if (request == null)
                throw new UserException("Invalid request");

            if (string.IsNullOrEmpty(request.OldPassword))
                throw new UserException("Old password is required");

            if (string.IsNullOrEmpty(request.NewPassword))
                throw new UserException("New password is required");

            if (request.NewPassword.Length < 6)
                throw new UserException("Password must be at least 6 characters long");

            if (request.NewPassword != request.ConfirmPassword)
                throw new UserException("New password and confirmation do not match");

            // Get authenticated user ID from token
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
            {
                throw new UserException("No HTTP context available");
            }

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
            {
                throw new UserException("User is not authenticated", 401);
            }

            int userId = JwtTokenManager.GetUserIdFromToken(authHeader);

            // Get user from database
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("User not found", 404);

            // Verify old password
            if (!VerifyPassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
                throw new UserException("Current password is incorrect");

            // Update password
            string salt;
            user.PasswordHash = HashPassword(request.NewPassword, out salt);
            user.PasswordSalt = salt;

            await _context.SaveChangesAsync();
            return true;
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

        public async Task<AuthResponse> AuthenticateAsync(LoginRequest request)
        {
            // Include Role in the query to avoid additional database calls
            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Username == request.Username);
            
            if(user == null)
                return null;
            
            if(!VerifyPassword(request.Password, user.PasswordSalt, user.PasswordHash))
                return null;
            
            // Update last login time
            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            
            var token = GenerateToken(user);
            if(token == null)
                return null;
            
            var response = new AuthResponse{    
                UserId = user.Id,
                Token = token,
                RoleId = user.RoleId,
                RoleName = user.Role.Name
            };
            return response;
        }

        private string GenerateToken(User user)
        {
            // Load user with role information
            var entity = _context.Users.Include(u => u.Role).FirstOrDefault(u => u.Id == user.Id);
            if(entity == null)
                return null;
            
            // Use entity with role information
            List<Claim> claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, entity.Id.ToString()),
                new Claim(ClaimTypes.Name, entity.Username),
                new Claim(ClaimTypes.Role, entity.Role.Name),
                new Claim(ClaimTypes.Email, entity.Email)
            };
            
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config.GetSection("JwtConfig:Key").Value));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var token = new JwtSecurityToken(
                _config.GetSection("JwtConfig:Issuer").Value,
                _config.GetSection("JwtConfig:Audience").Value,
                claims,
                expires: DateTime.UtcNow.AddDays(1),
                signingCredentials: credentials
            );
            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private void ValidateUserRequest(UserUpsertRequest request)
        {
            // Username validation
            if (string.IsNullOrWhiteSpace(request.Username))
                throw new UserException("Username is required");
                
            if (request.Username.Length < 3)
                throw new UserException("Username must be at least 3 characters long");
                
            if (request.Username.Length > 50)
                throw new UserException("Username cannot exceed 50 characters");

            // Email validation
            if (string.IsNullOrWhiteSpace(request.Email))
                throw new UserException("Email is required");
                
            if (request.Email.Length > 100)
                throw new UserException("Email cannot exceed 100 characters");
                
            // Basic email format validation
            if (!request.Email.Contains("@") || !request.Email.Contains("."))
                throw new UserException("Invalid email format");

            // Name validation
            if (string.IsNullOrWhiteSpace(request.FirstName))
                throw new UserException("First name is required");
                
            if (request.FirstName.Length > 50)
                throw new UserException("First name cannot exceed 50 characters");

            if (string.IsNullOrWhiteSpace(request.LastName))
                throw new UserException("Last name is required");
                
            if (request.LastName.Length > 50)
                throw new UserException("Last name cannot exceed 50 characters");

            // Phone validation
            if (request.PhoneNumber != null && request.PhoneNumber.Length > 20)
                throw new UserException("Phone number cannot exceed 20 characters");
        }

        public async Task<UserResponse> GetMeAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
                throw new UserException("No HTTP context available");

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
                throw new UserException("User is not authenticated", 401);

            int userId = JwtTokenManager.GetUserIdFromToken(authHeader);
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("User not found", 404);

            return _mapper.Map<UserResponse>(user);
        }
    }
}