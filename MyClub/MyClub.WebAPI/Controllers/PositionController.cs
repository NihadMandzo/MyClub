using Microsoft.AspNetCore.Authorization;
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
    public class PositionController : BaseCRUDController<PositionResponse, BaseSearchObject, PositionUpsertRequest, PositionUpsertRequest>
    {
        public PositionController(IPositionService service) : base(service)
        {
        }
    }
} 