using System.Threading.Tasks;
using System.Collections.Generic;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IUserMembershipService : ICRUDService<UserMembershipResponse, UserMembershipSearchObject, UserMembershipUpsertRequest, UserMembershipUpsertRequest>
    {
        Task<UserMembershipResponse> PurchaseMembershipAsync(UserMembershipPurchaseRequest request);
        Task<UserMembershipResponse> RenewMembershipAsync(int userId, UserMembershipRenewalRequest request);
        Task<UserMembershipResponse> PurchaseMembershipForFriendAsync(UserMembershipFriendPurchaseRequest request);
        Task<List<UserMembershipResponse>> GetUserMembershipsAsync(int userId);
        Task<UserMembershipCardResponse> GetUserMembershipCardAsync(int membershipId);
        Task<bool> MarkAsShippedAsync(int membershipId);
    }
} 