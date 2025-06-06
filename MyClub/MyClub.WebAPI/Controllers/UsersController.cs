using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Services;
using System.Collections.Generic;
using System.Threading.Tasks;
using MyClub.Model.SearchObjects;
using Microsoft.AspNetCore.Authorization;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserUpsertRequest, UserUpsertRequest>
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService) : base(userService)
        {
            _userService = userService;
        }

        [Authorize]
        [HttpGet]
        public override async Task<PagedResult<UserResponse>> Get([FromQuery] UserSearchObject search)
        {
            var result = await _userService.GetAsync(search);
            return result;
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetMe()
        {
            var result = await _userService.GetMeAsync();
            return Ok(result);
        }

        [Authorize]
        [HttpGet("{id}")]
        public override async Task<UserResponse?> GetById(int id)
        {
            var result = await _userService.GetByIdAsync(id);
            return result;
        }   

        [Authorize] 
        [HttpPut("{id}")]
        public override async Task<IActionResult> Update(int id, [FromBody] UserUpsertRequest request)
        {
            var result = await _userService.UpdateAsync(id, request);
            return Ok(result);
        }

        [Authorize]
        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            var result = await _userService.DeleteAsync(id);
            return Ok(result);
        }

        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var result = await _userService.ChangePasswordAsync(request);
            return Ok(result);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Authenticate([FromBody] LoginRequest request)
        {
            var result = await _userService.AuthenticateAsync(request);
            return Ok(result);
        }

        [HttpPost("register")]
        public override async Task<IActionResult> Create([FromBody] UserUpsertRequest request)
        {
            var result = await _userService.CreateAsync(request);
            return Ok(result);
        }

    }
} 