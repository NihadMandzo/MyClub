using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Mvc;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProductController : BaseCRUDController<ProductResponse, ProductSearchObject, ProductUpsertRequest, ProductUpsertRequest>
    {
        private readonly IProductService _productService;
        
        public ProductController(IProductService service) : base(service)
        {
            _productService = service;
        }
        
        [HttpGet("{id}")]
        public override async Task<ProductResponse?> GetById(int id)
        {
            return await _productService.GetByIdAsync(id);
        }
        
        [HttpPost]
        public override async Task<IActionResult> Create([FromForm] ProductUpsertRequest request)
        {
            ProcessSizeArrays(request);
            return Ok(await _productService.CreateAsync(request));
        }
        
        [HttpPut("{id}")]
        public override async Task<IActionResult> Update(int id, [FromForm] ProductUpsertRequest request)
        {
            ProcessSizeArrays(request);
            return Ok(await _productService.UpdateAsync(id, request));
        }
        
        
        private void ProcessSizeArrays(ProductUpsertRequest request)
        {
            // Clear existing product sizes
            request.ProductSizes.Clear();
            
            // Process the SizeIds and Quantities arrays
            if (request.SizeIds != null && request.Quantities != null)
            {
                // Use the minimum length of both arrays to avoid index out of range
                int count = Math.Min(request.SizeIds.Count, request.Quantities.Count);
                
                for (int i = 0; i < count; i++)
                {
                    request.ProductSizes.Add(new ProductSizeRequest
                    {
                        SizeId = request.SizeIds[i],
                        Quantity = request.Quantities[i]
                    });
                }
            }
        }
    }
}