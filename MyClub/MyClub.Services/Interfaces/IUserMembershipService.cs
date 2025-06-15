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
        Task<PagedResult<UserMembershipResponse>> GetUserMembershipsAsync(int userId);
        Task<UserMembershipResponse> PurchaseMembershipAsync(UserMembershipUpsertRequest request);
        Task<UserMembershipCardResponse> GetUserMembershipCardAsync(int membershipId);
        Task<bool> MarkAsShippedAsync(int membershipId);
        Task<bool> HasActiveUserMembershipAsync(int userId);
        Task<decimal> CalculateDiscountedPriceAsync(int userId, decimal originalPrice);
    }
} 