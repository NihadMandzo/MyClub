using System.Threading.Tasks;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IMembershipCardService : ICRUDService<MembershipCardResponse, MembershipCardSearchObject, MembershipCardUpsertRequest, MembershipCardUpsertRequest>
    {
        Task<MembershipCardResponse> GetCurrentCampaignAsync();
        Task<MembershipCardStatsResponse> GetCampaignStatsAsync(int id);
    }
} 