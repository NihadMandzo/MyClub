using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Interfaces;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderController : BaseController<OrderResponse, OrderSearchObject>
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService service) : base(service)
        {
            _orderService = service;
        }

        [HttpPost("place-order")]
        [Authorize]
        public async Task<ActionResult<OrderResponse>> PlaceOrder([FromBody] OrderInsertRequest request)
        {
            return Ok(await _orderService.PlaceOrder(request));
        }

        [HttpGet]
        [Authorize(Policy = "AdminOnly")]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject search = null)
        {
            return await _orderService.GetAsync(search);
        }

        [HttpPut("{id}/status")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<OrderResponse>> ChangeOrderStatus(int id, [FromBody] OrderStateUpdateRequest request)
        {
            return Ok(await _orderService.ChangeOrderState(id, request));
        }

        [HttpPost("confirm")]
        [Authorize]
        public async Task<ActionResult<OrderResponse>> ConfirmOrder([FromBody] ConfirmOrderRequest request)
        {
            return Ok(await _orderService.ConfirmOrder(request));
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<OrderResponse?> GetById(int id)
        {
            return await _orderService.GetByIdAsync(id);
        }

        [HttpGet("user-orders")]
        [Authorize]
        public async Task<ActionResult<PagedResult<OrderResponse>>> GetUserOrders()
        {
            var userId = int.Parse(IHttpContextAccessor.HttpContext?.User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            return Ok(await _orderService.GetUserOrdersAsync(userId));
        }

        private IHttpContextAccessor IHttpContextAccessor => (IHttpContextAccessor)HttpContext.RequestServices.GetService(typeof(IHttpContextAccessor));
    }
} 