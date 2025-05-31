using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StadiumSectorController : BaseController<StadiumSector, BaseSearchObject>
    {
        public StadiumSectorController(IStadiumSectorService service) : base(service)
        {
        }

    }
}
