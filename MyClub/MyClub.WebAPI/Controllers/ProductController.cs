using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : BaseCRUDController<ProductResponse, ProductSearchObject, ProductUpsertRequest, ProductUpsertRequest>
    {
        private readonly IProductService _productService;
        public ProductController(IProductService productService) : base(productService)
        {
            _productService = productService;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Create([FromForm] ProductUpsertRequest request)
        {
            ProcessSizeArrays(request);
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<IActionResult> Update(int id, [FromForm] ProductUpsertRequest request)
        {
            ProcessSizeArrays(request);
            return await base.Update(id, request);
        }

        [HttpGet("recommender/{userId}")]
        public async Task<IActionResult> GetRecommendationAsync(int userId, int count = 5)
        {
            var recommendations = await _productService.GetRecommendationsAsync(userId, count);
            return Ok(recommendations);
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