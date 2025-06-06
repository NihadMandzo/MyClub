using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services;
using Microsoft.AspNetCore.Authorization;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CartController : BaseCRUDController<CartResponse, CartSearchObject, CartUpsertRequest, CartUpsertRequest>
    {
        private readonly ICartService _cartService;

        public CartController(ICartService service) : base(service)
        {
            _cartService = service;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetCartByUserId(int userId)
        {
            return Ok(await _cartService.GetCartByUserIdAsync(userId));
        }

        [HttpPost("{cartId}/items")]
        public async Task<IActionResult> AddItem(int cartId, [FromBody] CartItemUpsertRequest request)
        {
            return Ok(await _cartService.AddItemAsync(cartId, request));
        }

        [HttpPut("{cartId}/items/{itemId}")]
        public async Task<IActionResult> UpdateItem(int cartId, int itemId, [FromBody] CartItemUpsertRequest request)
        {
            return Ok(await _cartService.UpdateItemAsync(cartId, itemId, request));
        }

        [HttpDelete("{cartId}/items/{itemId}")]
        public async Task<IActionResult> RemoveItem(int cartId, int itemId)
        {
            return Ok(await _cartService.RemoveItemAsync(cartId, itemId));
        }

        [HttpDelete("{cartId}/clear")]
        public async Task<IActionResult> ClearCart(int cartId)
        {
            return Ok(await _cartService.ClearCartAsync(cartId));
        }
    }
} 