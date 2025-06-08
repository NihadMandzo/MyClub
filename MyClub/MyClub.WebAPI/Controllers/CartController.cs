using Microsoft.AspNetCore.Mvc;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace MyClub.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize] // Ensure all cart operations require authentication
    public class CartController : ControllerBase
    {
        private readonly ICartService _cartService;

        public CartController(ICartService service)
        {
            _cartService = service;
        }

        /// <summary>
        /// Get current user's cart
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetCurrentUserCart()
        {
            int userId = GetAuthenticatedUserId();
            var cart = await _cartService.GetCartByUserIdAsync(userId);
            if (cart == null)
                return Ok(new { Message = "Cart is empty" });
            
            return Ok(cart);
        }

        /// <summary>
        /// Add item to current user's cart
        /// </summary>
        [HttpPost("items")]
        public async Task<IActionResult> AddToCart([FromBody] CartItemUpsertRequest request)
        {
            if (request == null)
                throw new UserException("Request cannot be null");
                
            int userId = GetAuthenticatedUserId();
            return Ok(await _cartService.AddToCartAsync(userId, request));
        }

        /// <summary>
        /// Update item in current user's cart
        /// </summary>
        [HttpPut("items/{itemId}")]
        public async Task<IActionResult> UpdateCartItem(int itemId, [FromBody] CartItemUpsertRequest request)
        {
            if (request == null)
                throw new UserException("Request cannot be null");
                
            int userId = GetAuthenticatedUserId();
            return Ok(await _cartService.UpdateCartItemAsync(userId, itemId, request));
        }

        /// <summary>
        /// Remove item from current user's cart
        /// </summary>
        [HttpDelete("items/{itemId}")]
        public async Task<IActionResult> RemoveFromCart(int itemId)
        {
            int userId = GetAuthenticatedUserId();
            return Ok(await _cartService.RemoveFromCartAsync(userId, itemId));
        }

        /// <summary>
        /// Clear current user's cart
        /// </summary>
        [HttpDelete("clear")]
        public async Task<IActionResult> ClearCart()
        {
            int userId = GetAuthenticatedUserId();
            return Ok(await _cartService.ClearCartAsync(userId));
        }

        /// <summary>
        /// Gets the currently authenticated user's ID from the JWT token claims
        /// </summary>
        /// <returns>The authenticated user's ID</returns>
        /// <exception cref="UserException">Thrown if the user is not authenticated or user ID claim is missing</exception>
        private int GetAuthenticatedUserId()
        {
            // Get user ID from claims
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
            {
                throw new UserException("User is not authenticated or user ID claim is missing", 401);
            }

            if (!int.TryParse(userIdClaim.Value, out int userId))
            {
                throw new UserException("Invalid user ID format in authentication token", 401);
            }

            return userId;
        }
    }
}
