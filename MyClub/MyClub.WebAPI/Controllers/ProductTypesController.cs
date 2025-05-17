using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Services;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductTypesController : ControllerBase
    {
        private readonly IProductTypeService _productTypeService;

        public ProductTypesController(IProductTypeService productTypeService)
        {
            _productTypeService = productTypeService;
        }

        // GET: api/producttypes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProductTypeResponse>>> GetAll()
        {
            var productTypes = await _productTypeService.GetAllAsync();
            return Ok(productTypes);
        }

        // GET: api/producttypes/5
        [HttpGet("{id}")]
        public async Task<ActionResult<ProductTypeResponse>> GetById(int id)
        {
            var productType = await _productTypeService.GetByIdAsync(id);

            if (productType == null)
                return NotFound();

            return Ok(productType);
        }

        // POST: api/producttypes
        [HttpPost]
        public async Task<ActionResult<ProductTypeResponse>> Create(ProductTypeUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var createdProductType = await _productTypeService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdProductType.Id }, createdProductType);
        }

        // PUT: api/producttypes/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ProductTypeUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var updatedProductType = await _productTypeService.UpdateAsync(id, request);
            
            if (updatedProductType == null)
                return NotFound();

            return NoContent();
        }

        // DELETE: api/producttypes/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var result = await _productTypeService.DeleteAsync(id);
            
            if (!result)
                return NotFound();

            return NoContent();
        }
    }
} 