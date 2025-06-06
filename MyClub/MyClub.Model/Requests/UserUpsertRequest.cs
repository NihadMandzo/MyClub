using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class UserUpsertRequest
    {
        [Required]
        [StringLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [StringLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [StringLength(20)]
        [Phone]
        public string? PhoneNumber { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        // Password is only required for new users
        [StringLength(100, MinimumLength = 6)]
        public string? Password { get; set; }
        
        // Role ID (null means keep existing role or use default)
        public int? RoleId { get; set; }
    }
} 