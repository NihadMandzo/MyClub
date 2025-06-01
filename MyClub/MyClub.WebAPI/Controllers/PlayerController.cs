using System;
using Microsoft.AspNetCore.Mvc;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PlayerController : BaseCRUDController<Model.Responses.PlayerResponse, Model.SearchObjects.PlayerSearchObject, Model.Requests.PlayerInsertRequest, Model.Requests.PlayerUpdateRequest>
    {
        public PlayerController(Services.Interfaces.IPlayerInterface service) : base(service)
        {
        }
    }
}