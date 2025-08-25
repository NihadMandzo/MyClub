using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class ResetPasswordRequest
    {
        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [MaxLength(6)]
        [MinLength(6)]
        public string ResetCode { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string NewPassword { get; set; } = string.Empty;

        [Required]
        [Compare("NewPassword")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
