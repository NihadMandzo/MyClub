using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model;
using MyClub.Model.Requests;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StadiumSectorController : BaseCRUDController<StadiumSectorResponse, BaseSearchObject, StadiumSectorUpsertRequest, StadiumSectorUpsertRequest>
    {
        public StadiumSectorController(IStadiumSectorService service) : base(service)
        {
        }
    }
}
