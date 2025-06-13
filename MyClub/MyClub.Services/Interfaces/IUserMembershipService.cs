using System.Threading.Tasks;
using System.Collections.Generic;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services.Interfaces
{
    public interface IUserMembershipService : ICRUDService<UserMembershipResponse, UserMembershipSearchObject, UserMembershipUpsertRequest, UserMembershipUpsertRequest>
    {
        Task<List<UserMembershipResponse>> GetUserMembershipsAsync(int userId);
        Task<UserMembershipResponse> PurchaseMembershipAsync(UserMembershipUpsertRequest request);
        Task<UserMembershipCardResponse> GetUserMembershipCardAsync(int membershipId);
        Task<bool> MarkAsShippedAsync(int membershipId);
    }
} 