using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using MyClub.Services.Helpers;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserMembershipController : BaseCRUDController<UserMembershipResponse, UserMembershipSearchObject, UserMembershipUpsertRequest, UserMembershipUpsertRequest>
    {
        private readonly IUserMembershipService _service;

        public UserMembershipController(IUserMembershipService service) : base(service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize(Policy = "AdminOnly")]
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
        public async Task<IActionResult> PurchaseMembership([FromBody] UserMembershipPurchaseRequest request)
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

        [HttpPost("renew")]
        public async Task<IActionResult> RenewMembership([FromBody] UserMembershipRenewalRequest request)
        {
            try
            {
                var userId = JwtTokenManager.GetUserIdFromToken(HttpContext.Request.Headers["Authorization"].ToString());
                var result = await _service.RenewMembershipAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("purchase-for-friend")]
        public async Task<IActionResult> PurchaseMembershipForFriend([FromBody] UserMembershipFriendPurchaseRequest request)
        {
            try
            {
                var result = await _service.PurchaseMembershipForFriendAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("{id}/mark-shipped")]
        [Authorize(Policy = "AdminOnly")]
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

        // Admin CRUD operations - override base methods to add authorization
        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Create([FromBody] UserMembershipUpsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Update(int id, [FromBody] UserMembershipUpsertRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
} 