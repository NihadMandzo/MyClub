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
            request.UserId = userId;
            
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