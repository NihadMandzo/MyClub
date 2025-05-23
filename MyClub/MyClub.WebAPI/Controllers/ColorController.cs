using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ColorController : BaseController<ColorResponse, ColorSearchObject>
    {
        public ColorController(IColorService service) : base(service)
        {
        }
    }
}
