using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace MyClub.WebAPI
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MatchController : BaseCRUDController<MatchResponse, BaseSearchObject, MatchUpsertRequest, MatchUpsertRequest>
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


        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableMatches([FromQuery] BaseSearchObject search)
        {
            if (search == null)
                search = new BaseSearchObject();

            // Use the dedicated service method instead of filtering in memory
            var result = await _matchService.GetAvailableMatchesAsync(search);
            return Ok(result);
        }

        [HttpPost("tickets/{ticketId}/purchase")]
        public async Task<ActionResult<UserTicketResponse>> PurchaseTicket(int ticketId, [FromBody] TicketPurchaseRequest request)
        {
            // Get the user ID from the auth token
            int userId = GetUserIdFromToken();

            request.MatchTicketId = ticketId;


            var result = await _matchService.PurchaseTicketAsync(request);
            return Ok(result);
        }

        [HttpGet("user-tickets")]
        public async Task<IActionResult> GetUserTickets([FromQuery] bool upcoming = false)
        {
            // Get the user ID from the auth token
            int userId = GetUserIdFromToken();

            var result = await _matchService.GetUserTicketsAsync(userId, upcoming);
            return Ok(result);
        }

        [HttpPost("validate-ticket")]
        public async Task<ActionResult<QRValidationResponse>> ValidateTicket([FromBody] QRValidationRequest request)
        {
            var result = await _matchService.ValidateQRCodeAsync(request);
            return Ok(result);
        }

        // Helper method to get user ID from token
        private int GetUserIdFromToken()
        {
            // Get the user ID from the claims
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
            {
                return userId;
            }

            throw new UnauthorizedAccessException("User ID not found in token");
        }

        [HttpPut("result/{matchId}")]
        public async Task<IActionResult> UpdateMatchResultAsync(int matchId, [FromBody] MatchResultRequest request)
        {
            if (request == null)
            {
                return BadRequest("Match result request cannot be null");
            }

            // Validate the match ID
            if (matchId <= 0)
            {
                return BadRequest("Invalid match ID");
            }

            // Call the service to set the match result
            try
            {
                var result = await _matchService.UpdateMatchResultAsync(matchId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost("tickets/{matchId}")]
        public async Task<IActionResult> CreateOrUpdateMatchTicket(int matchId, [FromBody] List<MatchTicketUpsertRequest> request)
        {
            if (request == null)
            {
                return BadRequest("Match ticket request cannot be null");
            }

            // Validate the match ID
            if (matchId <= 0)
            {
                return BadRequest("Invalid match ID");
            }

                var result = await _matchService.CreateOrUpdateMatchTicketAsync(matchId, request);
                return Ok(result);

        }
    }

} 