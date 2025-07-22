using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace MyClub.WebAPI
{
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch>  
    where T : class where TSearch : BaseSearchObject, new() where TInsert : class where TUpdate : class
    {
        protected readonly ICRUDService<T, TSearch, TInsert, TUpdate> _service;

        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public virtual async Task<IActionResult> Create([FromBody] TInsert request)
        {
            return Ok(await _service.CreateAsync(request));
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public virtual async Task<IActionResult> Update(int id, [FromBody] TUpdate request)
        {
            return Ok(await _service.UpdateAsync(id, request));
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            return Ok(await _service.DeleteAsync(id));
        }
    }
}
