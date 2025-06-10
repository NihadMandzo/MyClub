using System;

namespace MyClub.Model.Responses
{
    public class UserMembershipResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; }
        public int MembershipCardId { get; set; }
        public string MembershipName { get; set; }
        public int Year { get; set; }
        public DateTime JoinDate { get; set; }
        public bool IsRenewal { get; set; }
        public int? PreviousMembershipId { get; set; }
        public bool PhysicalCardRequested { get; set; }
        public string RecipientFullName { get; set; }
        public string RecipientEmail { get; set; }
        public string ShippingAddress { get; set; }
        public string ShippingCity { get; set; }
        public string ShippingPostalCode { get; set; }
        public string ShippingCountry { get; set; }
        public bool IsShipped { get; set; }
        public DateTime? ShippedDate { get; set; }
        public decimal PaymentAmount { get; set; }
        public bool IsPaid { get; set; }
        public DateTime? PaymentDate { get; set; }
    }
} 