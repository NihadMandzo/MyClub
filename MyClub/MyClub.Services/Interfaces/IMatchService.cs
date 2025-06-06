using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IMatchService : ICRUDService<MatchResponse, MatchSearchObject, MatchUpsertRequest, MatchUpsertRequest>
    {
        Task<MatchResponse> UpdateMatchResultAsync(int matchId, int homeGoals, int awayGoals);
        Task<MatchResponse> UpdateMatchStatusAsync(int matchId, string status);
        Task<List<MatchResponse>> GetUpcomingMatchesAsync(int? clubId = null, int? count = null);
        Task<List<MatchResponse>> GetRecentMatchesAsync(int? clubId = null, int? count = null);
    }
} 