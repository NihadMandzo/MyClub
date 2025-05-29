using System;

namespace MyClub.Model.Responses
{

    public class AuthResponse
    {
        public int UserId { get; set; }
        public string Token { get; set; }
        public int RoleId { get; set; }
        public string RoleName { get; set; }
    }
}
