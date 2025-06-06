using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface ICartService : ICRUDService<CartResponse, CartSearchObject, CartUpsertRequest, CartUpsertRequest>
    {
        Task<CartResponse> AddItemAsync(int cartId, CartItemUpsertRequest request);
        Task<CartResponse> UpdateItemAsync(int cartId, int itemId, CartItemUpsertRequest request);
        Task<CartResponse> RemoveItemAsync(int cartId, int itemId);
        Task<CartResponse> ClearCartAsync(int cartId);
        Task<CartResponse> GetCartByUserIdAsync(int userId);
    }
} 