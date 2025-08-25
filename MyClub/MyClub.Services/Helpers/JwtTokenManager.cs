using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using MyClub.Model.Responses;

namespace MyClub.Services.Helpers{
    public static class JwtTokenManager
    {
        public static int GetUserIdFromToken(string authorizationHeader)
        {
            if (string.IsNullOrEmpty(authorizationHeader))
                throw new UserException("Greška u autorizaciji", 401);

            // Remove "Bearer " prefix if present
            string token = authorizationHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authorizationHeader.Substring("Bearer ".Length).Trim()
                : authorizationHeader.Trim();

            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);

            // Get the user ID claim
            var userIdClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
                throw new UserException("Korisnički ID nije pronađen u tokenu", 401);

            if (!int.TryParse(userIdClaim.Value, out int userId))
                throw new UserException("Nevažeći korisnički ID u tokenu", 401);

            return userId;
        }

        public static string GetUsernameFromToken(string authorizationHeader)
        {
            if (string.IsNullOrEmpty(authorizationHeader))
                throw new UserException("Greška u autorizaciji", 401);

            // Remove "Bearer " prefix if present
            string token = authorizationHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authorizationHeader.Substring("Bearer ".Length).Trim()
                : authorizationHeader.Trim();

            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);

            // Get the username claim
            var usernameClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Name);
            if (usernameClaim == null)
                throw new UserException("Korisničko ime nije pronađeno u tokenu", 401);

            return usernameClaim.Value;
        }

        public static string GetRoleFromToken(string authorizationHeader)
        {
            if (string.IsNullOrEmpty(authorizationHeader))
                throw new UserException("Greška u autorizaciji", 401);

            // Remove "Bearer " prefix if present
            string token = authorizationHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authorizationHeader.Substring("Bearer ".Length).Trim()
                : authorizationHeader.Trim();

            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);

            // Get the role claim
            var roleClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Role);
            if (roleClaim == null)
                throw new UserException("Uloga nije pronađena u tokenu", 401);

            return roleClaim.Value;
        }
        public static bool IsAdmin(string authorizationHeader)
        {
            if (string.IsNullOrEmpty(authorizationHeader))
                throw new UserException("Greška u autorizaciji", 401);

            // Remove "Bearer " prefix if present
            string token = authorizationHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authorizationHeader.Substring("Bearer ".Length).Trim()
                : authorizationHeader.Trim();

            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);

            // Check if the role claim is "Admin"
            var roleClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Role && c.Value.Equals("Administrator", StringComparison.OrdinalIgnoreCase));
            return roleClaim != null;
        }
    }
} 