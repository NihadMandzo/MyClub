using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CommentController : BaseCRUDController<CommentResponse, CommentSearchObject, CommentUpsertRequest, CommentUpsertRequest>
    {
        public CommentController(ICommentService service) : base(service)
        {
        }
    }
}
