using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class UserMembership
    {
        // Composite key is configured in DbContext
        public int UserId { get; set; }
        public int MembershipCardId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        
        [ForeignKey("MembershipCardId")]
        public virtual MembershipCard MembershipCard { get; set; }
        
        public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    }
} 