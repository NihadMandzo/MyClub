using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface ICartService
    {
        Task<CartResponse> GetCartByUserIdAsync(int userId);
        Task<CartResponse> AddToCartAsync(int userId, CartItemUpsertRequest request);
        Task<CartResponse> UpdateCartItemAsync(int userId, int itemId, CartItemUpsertRequest request);
        Task<CartResponse> RemoveFromCartAsync(int userId, int itemId);
        Task<CartResponse> ClearCartAsync(int userId);
    }
} 