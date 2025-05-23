using System;
using Microsoft.AspNetCore.Mvc;
using MyClub.Services;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class BaseController<T, TSearch> : ControllerBase where T : class where TSearch : class, new()
    {
        private readonly IService<T, TSearch> _service;

        public BaseController(IService<T, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IEnumerable<T>> Get([FromQuery] TSearch? search = null)
        {
            return await _service.GetAsync(search ?? new TSearch());
        }

        [HttpGet("{id}")]
        public async Task<T?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }

        
    }
}
