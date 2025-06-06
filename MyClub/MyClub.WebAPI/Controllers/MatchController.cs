using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Authorization;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class MatchController : BaseCRUDController<MatchResponse, MatchSearchObject, MatchUpsertRequest, MatchUpsertRequest>
    {
        private readonly IMatchService _matchService;

        public MatchController(IMatchService service) : base(service)
        {
            _matchService = service;
        }

        [HttpGet("upcoming")]
        public async Task<IActionResult> GetUpcomingMatches([FromQuery] int? clubId = null, [FromQuery] int? count = null)
        {
            return Ok(await _matchService.GetUpcomingMatchesAsync(clubId, count));
        }

        [HttpGet("recent")]
        public async Task<IActionResult> GetRecentMatches([FromQuery] int? clubId = null, [FromQuery] int? count = null)
        {
            return Ok(await _matchService.GetRecentMatchesAsync(clubId, count));
        }

        [HttpPatch("{id}/result")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> UpdateMatchResult(int id, [FromBody] UpdateMatchResultRequest request)
        {
            return Ok(await _matchService.UpdateMatchResultAsync(id, request.HomeGoals, request.AwayGoals));
        }

        [HttpPatch("{id}/status")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> UpdateMatchStatus(int id, [FromBody] UpdateMatchStatusRequest request)
        {
            return Ok(await _matchService.UpdateMatchStatusAsync(id, request.Status));
        }
    }

    public class UpdateMatchResultRequest
    {
        public int HomeGoals { get; set; }
        public int AwayGoals { get; set; }
    }

    public class UpdateMatchStatusRequest
    {
        public string Status { get; set; }
    }
} 