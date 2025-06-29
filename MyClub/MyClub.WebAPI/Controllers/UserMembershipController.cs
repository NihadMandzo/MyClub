using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using MyClub.Services.Helpers;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserMembershipController : BaseController<UserMembershipResponse, UserMembershipSearchObject>
    {
        private readonly IUserMembershipService _service;

        public UserMembershipController(IUserMembershipService service) : base(service)
        {
            _service = service;
        }

        [HttpGet]
        public override async Task<PagedResult<UserMembershipResponse>> Get([FromQuery] UserMembershipSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        public override async Task<UserMembershipResponse?> GetById(int id)
        {
            // Check if user is authorized to access this membership
            var userId = JwtTokenManager.GetUserIdFromToken(HttpContext.Request.Headers["Authorization"].ToString());
            var membership = await _service.GetByIdAsync(id);
            
            if (membership == null)
            {
                return null;
            }
            
            // Allow access if user is admin or the membership belongs to the user
            if (User.IsInRole("Admin") || membership.UserId == userId)
            {
                return membership;
            }
            
            return null;
        }

        [HttpGet("user")]
        public async Task<IActionResult> GetUserMemberships()
        {
            var userId = JwtTokenManager.GetUserIdFromToken(HttpContext.Request.Headers["Authorization"].ToString());
            var memberships = await _service.GetUserMembershipsAsync(userId);
            return Ok(memberships);
        }

        [HttpGet("{id}/card")]
        public async Task<IActionResult> GetMembershipCard(int id)
        {
            var userId = JwtTokenManager.GetUserIdFromToken(HttpContext.Request.Headers["Authorization"].ToString());
            var membership = await _service.GetByIdAsync(id);
            
            if (membership == null)
            {
                return NotFound($"Membership with ID {id} not found");
            }
            
            // Allow access if user is admin or the membership belongs to the user
            if (User.IsInRole("Admin") || membership.UserId == userId)
            {
                var card = await _service.GetUserMembershipCardAsync(id);
                if (card == null)
                {
                    return NotFound($"Membership card for ID {id} not found");
                }
                return Ok(card);
            }
            
            return Forbid();
        }

        [HttpPost("purchase")]
        public async Task<IActionResult> PurchaseMembership([FromBody] UserMembershipUpsertRequest request)
        {
            try
            {
                var result = await _service.PurchaseMembershipAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("{id}/mark-shipped")]
        public async Task<IActionResult> MarkAsShipped(int id)
        {
            try
            {
                var result = await _service.MarkAsShippedAsync(id);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

    }
} 