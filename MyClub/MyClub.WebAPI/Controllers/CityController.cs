using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CityController : BaseCRUDController<CityResponse, BaseSearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CityController(ICityService service) : base(service)
        {
        }
    }
}
