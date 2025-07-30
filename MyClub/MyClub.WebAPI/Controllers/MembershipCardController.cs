using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MembershipCardController : BaseCRUDController<MembershipCardResponse, MembershipCardSearchObject, MembershipCardUpsertRequest, MembershipCardUpsertRequest>
    {
        private readonly IMembershipCardService _service;

        public MembershipCardController(IMembershipCardService service) : base(service)
        {
            _service = service;
        }

        [HttpGet]
        public override async Task<PagedResult<MembershipCardResponse>> Get([FromQuery] MembershipCardSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        public override async Task<MembershipCardResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpGet("current")]
        public async Task<IActionResult> GetCurrentCampaign()
        {
            var result = await _service.GetCurrentCampaignAsync();
            if (result == null)
            {
                return NotFound("No active membership campaign found");
            }
            return Ok(result);
        }

        [HttpGet("{id}/stats")]
        public async Task<IActionResult> GetCampaignStats(int id)
        {
            var result = await _service.GetCampaignStatsAsync(id);
            if (result == null)
            {
                return NotFound($"Membership campaign with ID {id} not found");
            }
            return Ok(result);
        }

        [HttpPost]
        public override async Task<IActionResult> Create([FromForm] MembershipCardUpsertRequest request)
        {
            return Ok(await _service.CreateAsync(request));
        }

        [HttpPut("{id}")]
        public override async Task<IActionResult> Update(int id, [FromForm] MembershipCardUpsertRequest request)
        {
            return Ok(await _service.UpdateAsync(id, request));
        }

        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            return Ok(await _service.DeleteAsync(id));
        }
    }
} 