using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class ForgotPasswordRequest
    {
        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;
    }
}
