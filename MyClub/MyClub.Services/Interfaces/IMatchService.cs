using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyClub.Services
{
    public interface IMatchService : ICRUDService<MatchResponse, BaseSearchObject, MatchUpsertRequest, MatchUpsertRequest>
    {
        Task<List<MatchResponse>> GetUpcomingMatchesAsync(int? clubId = null, int? count = null);

        Task<UserTicketResponse> PurchaseTicketAsync(TicketPurchaseRequest request);
        Task<PagedResult<UserTicketResponse>> GetUserTicketsAsync(int userId, bool upcomingOnly = false);
        Task<QRValidationResponse> ValidateQRCodeAsync(QRValidationRequest request);
        Task<PagedResult<MatchResponse>> GetAvailableMatchesAsync(BaseSearchObject search);
    }
} 