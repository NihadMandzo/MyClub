using System;

namespace MyClub.Model.SearchObjects
{
    public class UserMembershipSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? MembershipCardId { get; set; }
        public bool? IsRenewal { get; set; }
        public bool? PhysicalCardRequested { get; set; }
        public bool? IsShipped { get; set; }
        public bool? IsPaid { get; set; }
    }
} 