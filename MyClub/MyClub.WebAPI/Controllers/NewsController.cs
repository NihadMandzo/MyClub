using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NewsController : BaseCRUDController<NewsResponse, NewsSearchObject, NewsUpsertRequest, NewsUpsertRequest>
    {
        private readonly INewsService _service;
        public NewsController(INewsService service) : base(service)
        {
            _service = service;
        }


        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Create([FromForm] NewsUpsertRequest request){
            return Ok(await _service.CreateAsync(request));
        }

        
        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Update(int id, [FromForm] NewsUpsertRequest request){
            return Ok(await _service.UpdateAsync(id, request));
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Delete(int id){
            return Ok(await _service.DeleteAsync(id));
        }
    }
} 