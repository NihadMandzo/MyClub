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
using MyClub.Services.Helpers;

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
                throw new UserException("Email je već u upotrebi");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Korisničko ime je već zauzeto");

            // Set default values
            entity.CreatedAt = DateTime.UtcNow;
            entity.RoleId = request.RoleId ?? 2; // Default to regular user role if not specified

            // Hash password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                string salt;
                entity.PasswordHash = HashPassword(request.Password, out salt);
                entity.PasswordSalt = salt;
            }
            else
            {
                throw new UserException("Lozinka je obavezna");
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
                throw new UserException("Korisnik nije pronađen");

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
                throw new UserException("Email je već u upotrebi");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username && u.Id != entity.Id))
                throw new UserException("Korisničko ime je već zauzeto");

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
                throw new UserException("Korisnik nije pronađen");

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
                    throw new UserException("Ne možete obrisati posljednji administratorski nalog");
                }
            }

            // Additional logic before deleting a user can be added here
            await Task.CompletedTask;
        }

        public async Task<bool> ChangePasswordAsync(ChangePasswordRequest request)
        {
            // Validate request
            if (request == null)
                throw new UserException("Nevažeći zahtev");

            if (string.IsNullOrEmpty(request.OldPassword))
                throw new UserException("Stara lozinka je obavezna");

            if (string.IsNullOrEmpty(request.NewPassword))
                throw new UserException("Nova lozinka je obavezna");

            if (request.NewPassword.Length < 6)
                throw new UserException("Lozinka mora imati najmanje 6 karaktera");

            if (request.NewPassword != request.ConfirmPassword)
                throw new UserException("Nova lozinka i potvrda se ne podudaraju");

            // Get authenticated user ID from token
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
            {
                throw new UserException("Greška");
            }

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
            {
                throw new UserException("Niste prijavljeni", 401);
            }

            int userId = JwtTokenManager.GetUserIdFromToken(authHeader);

            // Get user from database
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen", 404);

            // Verify old password
            if (!VerifyPassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
                throw new UserException("Stara lozinka je netačna");

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
            
            
            if (user == null)
                throw new UserException("Nevažeće korisničko ime ili lozinka", 401);

            if(!user.IsActive)
                throw new UserException("Korisnički nalog je deaktiviran", 403);

            if (!VerifyPassword(request.Password, user.PasswordSalt, user.PasswordHash))
                throw new UserException("Nevažeće korisničko ime ili lozinka", 401);

            // Update last login time
            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            
            var token = GenerateToken(user);
            if(token == null)
                throw new UserException("Greška prilikom generisanja tokena", 500);

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
                throw new UserException("Korisničko ime je obavezno");
                
            if (request.Username.Length < 3)
                throw new UserException("Korisničko ime mora imati najmanje 3 karaktera");
                
            if (request.Username.Length > 50)
                throw new UserException("Username ne može imati više od 50 karaktera");

            // Email validation
            if (string.IsNullOrWhiteSpace(request.Email))
                throw new UserException("Email je obavezan");

            if (request.Email.Length > 100)
                throw new UserException("Email ne može imati više od 100 karaktera");

            // Basic email format validation
            if (!request.Email.Contains("@") || !request.Email.Contains("."))
                throw new UserException("Neispravan format email adrese");

            // Name validation
            if (string.IsNullOrWhiteSpace(request.FirstName))
                throw new UserException("Ime je obavezno");

            if (request.FirstName.Length > 50)
                throw new UserException("Ime ne može imati više od 50 karaktera");

            if (string.IsNullOrWhiteSpace(request.LastName))
                throw new UserException("Prezime je obavezno");
                
            if (request.LastName.Length > 50)
                throw new UserException("Prezime ne može imati više od 50 karaktera");

            // Phone validation
            if (request.PhoneNumber != null && request.PhoneNumber.Length > 20)
                throw new UserException("Broj telefona ne može imati više od 20 karaktera");
        }

        public async Task<UserResponse> GetMeAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
                throw new UserException("Greška");

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
                throw new UserException("Niste prijavljeni", 401);

            int userId = JwtTokenManager.GetUserIdFromToken(authHeader);
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen", 404);

            return _mapper.Map<UserResponse>(user);
        }

        public async Task<bool> HasActiveUserMembership()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
                throw new UserException("Greška");

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
                throw new UserException("Niste prijavljeni", 401);

            int userId = JwtTokenManager.GetUserIdFromToken(authHeader);

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen", 404);

            return await _context.UserMemberships.AnyAsync(um => um.UserId == userId && um.MembershipCard.IsActive && um.MembershipCard.StartDate <= DateTime.UtcNow && um.MembershipCard.EndDate >= DateTime.UtcNow);
        }

        public async Task<bool> DeactivateSelfAsync()
        {
            int userId = GetCurrentUserId();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen");

            // Prevent deactivating last admin
            if (user.RoleId == 1)
            {
                int adminCount = await _context.Users.CountAsync(u => u.RoleId == 1 && u.IsActive);
                if (adminCount <= 1)
                    throw new UserException("Ne možete deaktivirati poslednji administratorski nalog");
            }

            user.IsActive = false;
            user.LastLogin = DateTime.UtcNow; // or null; adjust policy
            await _context.SaveChangesAsync();
            return true;
        }

        private int GetCurrentUserId()
        {
            var httpContext = _httpContextAccessor.HttpContext ?? throw new Exception("Greška");
            var auth = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(auth)) throw new Exception("Greška");
            return JwtTokenManager.GetUserIdFromToken(auth);
        }
    }
}