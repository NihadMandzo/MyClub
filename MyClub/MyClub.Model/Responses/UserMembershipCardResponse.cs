using System;

namespace MyClub.Model.Responses
{
    public class UserMembershipCardResponse
    {
        public int Id { get; set; }
        public string MembershipCardName { get; set; }
        public int Year { get; set; }
        public string UserFullName { get; set; }
        public DateTime JoinDate { get; set; }
        public string MembershipNumber { get; set; }
        public string CardImageUrl { get; set; }
        public bool IsActive { get; set; }
        public DateTime ValidUntil { get; set; }
        public string QRCodeData { get; set; }
    }
} 