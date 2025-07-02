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
        public virtual async Task<PagedResult<T>> Get([FromQuery] TSearch? search = null)
        {
            Console.WriteLine($"BaseController.Get called for type {typeof(T).Name}");
            search = search ?? new TSearch();
            search.RetrieveAll = true; // Override to get all data in base controller
            var result = await _service.GetAsync(search);
            Console.WriteLine($"BaseController.Get returned {result.Data.Count} items");
            return result;
        }

        [HttpGet("{id}")]
        public virtual async Task<T?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}
