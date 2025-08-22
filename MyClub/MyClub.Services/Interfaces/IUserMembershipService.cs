using System.Threading.Tasks;
using System.Collections.Generic;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Helpers;

namespace MyClub.Services.Interfaces
{
    public interface IUserMembershipService : IService<UserMembershipResponse, UserMembershipSearchObject>
    {
        Task<PagedResult<UserMembershipCardResponse>> GetUserMembershipsAsync(int userId);
        Task<PaymentResponse> PurchaseMembershipAsync(MembershipPurchaseRequest request);
        Task<UserMembershipCardResponse> ConfirmPurchaseMembershipAsync(string transactionId);
        Task<bool> MarkAsShippedAsync(int membershipId);
        Task<UserMembershipCardResponse?> GetUserMembershipCardAsync(int membershipId);
    }
} 