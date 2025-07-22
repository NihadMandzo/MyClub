using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using MyClub.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace MyClub.WebAPI
{
    [ApiController]
    [Route("api/[controller]")]
    //[Authorize]
    public class BaseController<T, TSearch> : ControllerBase where T : class where TSearch : BaseSearchObject, new()
    {
        private readonly IService<T, TSearch> _service;

        public BaseController(IService<T, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize]
        public virtual async Task<PagedResult<T>> Get([FromQuery] TSearch? search = null)
        {
            var result = await _service.GetAsync(search);
            return result;
        }

        [HttpGet("{id}")]
        [Authorize]
        public virtual async Task<T?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}
