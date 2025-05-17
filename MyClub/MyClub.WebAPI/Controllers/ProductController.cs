using MyClub.Model;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Mvc;
using MyClub.Services.Database;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProductController : ControllerBase
    {
        protected readonly IProductService _productService;
        public ProductController(IProductService service) {
            _productService = service;
        }

        [HttpGet("")]
        public IEnumerable<Product> Get([FromQuery]ProductSearchObject? search)
        {
            return _productService.Get(search);
        }

        [HttpGet("{id}")]
        public Product Get(int id)
        {
            return _productService.Get(id);
        }
    }
}