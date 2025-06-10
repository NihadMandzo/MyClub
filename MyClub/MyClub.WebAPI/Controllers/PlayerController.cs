using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Interfaces;

namespace MyClub.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PlayerController : BaseCRUDController<PlayerResponse, PlayerSearchObject, PlayerInsertRequest, PlayerUpdateRequest>
    {
        private readonly IPlayerInterface _playerService;

        public PlayerController(IPlayerInterface service) : base(service)
        {
            _playerService = service;
        }

        [HttpPost]
        public override async Task<IActionResult> Create([FromForm] PlayerInsertRequest request)
        {
            return Ok(await _service.CreateAsync(request));
        }

        [HttpPut("{id}")]
        public override async Task<IActionResult> Update(int id, [FromForm] PlayerUpdateRequest request)
        {
            return Ok(await _service.UpdateAsync(id, request));
        }
        
    }
}