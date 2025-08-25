using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;
using System;
using System.Net;

namespace MyClub.Services
{
    public class CartService : ICartService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;

        public CartService(MyClubContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        /// <summary>
        /// Retrieves a user's cart by their user ID
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to retrieve</param>
        /// <returns>The user's cart if it exists, null otherwise</returns>
        /// <remarks>
        /// This method loads the cart with all its items and related product information.
        /// It does not create a cart if one doesn't exist - this follows the lazy cart creation
        /// pattern where carts are only created when a user adds their first product.
        /// </remarks>
        public async Task<CartResponse> GetCartByUserIdAsync(int userId)
        {
            await ValidateUserExistsAsync(userId);
            
            var cart = await _context.Carts
                .AsNoTracking()
                .Include(c => c.User)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(x => x.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                // Instead of creating a cart right away, we'll return null 
                // The cart will be created when the user adds the first item
                return null;
            }

            return MapToResponse(cart);
        }

        /// <summary>
        /// Adds a product to the user's cart
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to update</param>
        /// <param name="request">Information about the product to add</param>
        /// <returns>The updated cart</returns>
        /// <remarks>
        /// This method:
        /// 1. Gets or creates a cart for the user if one doesn't exist
        /// 2. Verifies the product exists and has enough stock
        /// 3. Checks if the item already exists in the cart:
        ///    - If it does, increases the quantity
        ///    - If not, adds a new item
        /// 4. Updates the cart's timestamp
        /// 5. Returns the updated cart with all related data
        /// </remarks>
        public async Task<CartResponse> AddToCartAsync(int userId, CartItemUpsertRequest request)
        {
            await ValidateUserExistsAsync(userId);
            ValidateCartItemRequest(request);

            // Get or create cart for user
            var cart = await GetOrCreateCartAsync(userId);

            // Validate product size and stock
            var productSize = await ValidateAndGetProductSizeAsync(request.ProductSizeId, request.Quantity);

            // Check if the item already exists in the cart
            var existingItem = cart.Items.FirstOrDefault(i => i.ProductSizeId == request.ProductSizeId);

            if (existingItem != null)
            {
                // Update the quantity of the existing item
                existingItem.Quantity += request.Quantity;
                
                // Check if the new quantity exceeds the stock
                await ValidateStockAvailabilityAsync(productSize.Id, existingItem.Quantity);
            }
            else
            {
                // Add a new item to the cart
                var newItem = new CartItem
                {
                    CartId = cart.Id,
                    ProductSizeId = request.ProductSizeId,
                    Quantity = request.Quantity,
                    AddedAt = DateTime.UtcNow
                };
                
                cart.Items.Add(newItem);
            }

            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data for response
            return await GetFullCartAsync(cart.Id);
        }

        /// <summary>
        /// Updates a specific item in the user's cart
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to update</param>
        /// <param name="itemId">The ID of the cart item to update</param>
        /// <param name="request">The new product size and quantity information</param>
        /// <returns>The updated cart</returns>
        /// <remarks>
        /// This method:
        /// 1. Retrieves the user's cart
        /// 2. Finds the specific item to update
        /// 3. Verifies the new product size exists and has enough stock
        /// 4. Updates the item's product size and quantity
        /// 5. Updates the cart's timestamp
        /// 6. Returns the updated cart with all related data
        /// </remarks>
        public async Task<CartResponse> UpdateCartItemAsync(int userId, int itemId, CartItemUpsertRequest request)
        {
            await ValidateUserExistsAsync(userId);
            await ValidateCartItemExistsInDatabaseAsync(itemId);
            ValidateCartItemRequest(request);

            // Get user's cart
            var cart = await GetUserCartAsync(userId);

            // Find and validate cart item
            var cartItem = await ValidateAndGetCartItemAsync(cart, itemId);

            // Validate product size and stock
            var productSize = await ValidateAndGetProductSizeAsync(request.ProductSizeId, request.Quantity);

            // Update the cart item
            cartItem.ProductSizeId = request.ProductSizeId;
            cartItem.Quantity = request.Quantity;
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data
            return await GetFullCartAsync(cart.Id);
        }

        /// <summary>
        /// Removes a specific item from the user's cart
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to update</param>
        /// <param name="itemId">The ID of the cart item to remove</param>
        /// <returns>The updated cart</returns>
        /// <remarks>
        /// This method:
        /// 1. Retrieves the user's cart
        /// 2. Finds the specific item to remove
        /// 3. Removes the item from the cart and database
        /// 4. Updates the cart's timestamp
        /// 5. Returns the updated cart with all related data
        /// </remarks>
        public async Task<CartResponse> RemoveFromCartAsync(int userId, int itemId)
        {
            await ValidateUserExistsAsync(userId);
            await ValidateCartItemExistsInDatabaseAsync(itemId);

            // Get user's cart
            var cart = await GetUserCartAsync(userId);

            // Find and validate cart item
            var cartItem = await ValidateAndGetCartItemAsync(cart, itemId);

            // Validate item ownership
            await ValidateCartItemOwnershipAsync(cartItem, userId);

            // Remove the item from the cart
            cart.Items.Remove(cartItem);
            _context.CartItems.Remove(cartItem);
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data
            return await GetFullCartAsync(cart.Id);
        }

        /// <summary>
        /// Removes all items from the user's cart
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to clear</param>
        /// <returns>The empty cart</returns>
        /// <remarks>
        /// This method:
        /// 1. Retrieves the user's cart
        /// 2. Removes all items from the cart and database
        /// 3. Updates the cart's timestamp
        /// 4. Returns the empty cart
        /// </remarks>
        public async Task<CartResponse> ClearCartAsync(int userId)
        {
            await ValidateUserExistsAsync(userId);

            // Get user's cart
            var cart = await GetUserCartAsync(userId);

            // Remove all items from the cart
            _context.CartItems.RemoveRange(cart.Items);
            cart.Items.Clear();
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Return the empty cart
            return await GetFullCartAsync(cart.Id);
        }

        #region Validation Methods

        /// <summary>
        /// Validates that the user exists in the database
        /// </summary>
        /// <param name="userId">The user ID to validate</param>
        /// <exception cref="UserException">Thrown if the user doesn't exist</exception>
        private async Task ValidateUserExistsAsync(int userId)
        {
            if (userId <= 0)
            {
                throw new UserException("Greška", (int)HttpStatusCode.BadRequest);
            }

            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
            {
                throw new UserException($"Korisnik nije pronađen", (int)HttpStatusCode.NotFound);
            }
        }

        /// <summary>
        /// Validates that the cart item exists in the database
        /// </summary>
        /// <param name="itemId">The item ID to validate</param>
        /// <exception cref="UserException">Thrown if the item doesn't exist</exception>
        private async Task ValidateCartItemExistsInDatabaseAsync(int itemId)
        {
            if (itemId <= 0)
            {
                throw new UserException("Greška", (int)HttpStatusCode.BadRequest);
            }

            var itemExists = await _context.CartItems.AnyAsync(i => i.Id == itemId);
            if (!itemExists)
            {
                throw new UserException($"Artikal u korpi sa ID {itemId} nije pronađen", (int)HttpStatusCode.NotFound);
            }
        }

        /// <summary>
        /// Validates that the cart item belongs to the specified user
        /// </summary>
        /// <param name="cartItem">The cart item to validate</param>
        /// <param name="userId">The user ID to check ownership against</param>
        /// <exception cref="UserException">Thrown if the item doesn't belong to the user</exception>
        private async Task ValidateCartItemOwnershipAsync(CartItem cartItem, int userId)
        {
            var cart = await _context.Carts.FirstOrDefaultAsync(c => c.Id == cartItem.CartId);
            if (cart.UserId != userId)
            {
                throw new UserException("Nemate dozvolu da mijenjate ovaj artikal u korpi", (int)HttpStatusCode.Forbidden);
            }
        }

        /// <summary>
        /// Validates a cart item request
        /// </summary>
        /// <param name="request">The request to validate</param>
        /// <exception cref="UserException">Thrown if the request is invalid</exception>
        private void ValidateCartItemRequest(CartItemUpsertRequest request)
        {
            if (request == null)
            {
                throw new UserException("Zahtjev za artikal u korpi ne može biti null", (int)HttpStatusCode.BadRequest);
            }

            if (request.ProductSizeId <= 0)
            {
                throw new UserException("ID veličine proizvoda mora biti veći od nule", (int)HttpStatusCode.BadRequest);
            }

            if (request.Quantity <= 0)
            {
                throw new UserException("Količina mora biti veća od nule", (int)HttpStatusCode.BadRequest);
            }

            if (request.Quantity > 100)
            {
                throw new UserException("Maksimalna količina po artiklu je 100", (int)HttpStatusCode.BadRequest);
            }
        }

        /// <summary>
        /// Gets a user's cart or throws an exception if it doesn't exist
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to get</param>
        /// <returns>The user's cart</returns>
        /// <exception cref="UserException">Thrown if the cart doesn't exist</exception>
        private async Task<Database.Cart> GetUserCartAsync(int userId)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                throw new UserException($"Korpa nije pronađena za korisnika", (int)HttpStatusCode.NotFound);
            }

            return cart;
        }

        /// <summary>
        /// Gets or creates a cart for a user
        /// </summary>
        /// <param name="userId">The ID of the user whose cart to get or create</param>
        /// <returns>The user's cart</returns>
        private async Task<Database.Cart> GetOrCreateCartAsync(int userId)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                // Create a new cart for the user
                cart = new Database.Cart
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    Items = new List<CartItem>()
                };
                
                _context.Carts.Add(cart);
                
                // User existence has already been validated
            }

            return cart;
        }

        /// <summary>
        /// Validates and gets a cart item
        /// </summary>
        /// <param name="cart">The cart containing the item</param>
        /// <param name="itemId">The ID of the item to get</param>
        /// <returns>The cart item</returns>
        /// <exception cref="UserException">Thrown if the item doesn't exist</exception>
        private async Task<CartItem> ValidateAndGetCartItemAsync(Database.Cart cart, int itemId)
        {
            var cartItem = cart.Items.FirstOrDefault(i => i.Id == itemId);

            if (cartItem == null)
            {
                throw new UserException($"Artikal u korpi sa ID {itemId} nije pronađen", (int)HttpStatusCode.NotFound);
            }

            return await Task.FromResult(cartItem);
        }

        /// <summary>
        /// Validates and gets a product size
        /// </summary>
        /// <param name="productSizeId">The ID of the product size to get</param>
        /// <param name="requestedQuantity">The requested quantity</param>
        /// <returns>The product size</returns>
        /// <exception cref="UserException">Thrown if the product size doesn't exist or there's not enough stock</exception>
        private async Task<ProductSize> ValidateAndGetProductSizeAsync(int productSizeId, int requestedQuantity)
        {
            var productSize = await _context.ProductSizes
                .Include(ps => ps.Product)
                .Include(ps => ps.Size)
                .FirstOrDefaultAsync(ps => ps.Id == productSizeId);

            if (productSize == null)
            {
                throw new UserException($"Veličina proizvoda sa ID {productSizeId} nije pronađena", (int)HttpStatusCode.NotFound);
            }

            if (productSize.Quantity < requestedQuantity)
            {
                throw new UserException($"Nema dovoljno zaliha za proizvod '{productSize.Product?.Name}' u veličini '{productSize.Size?.Name}'. Dostupno: {productSize.Quantity}", (int)HttpStatusCode.BadRequest);
            }

            return productSize;
        }

        /// <summary>
        /// Validates that there's enough stock for a product size
        /// </summary>
        /// <param name="productSize">The product size to check</param>
        /// <param name="requestedQuantity">The requested quantity</param>
        /// <exception cref="UserException">Thrown if there's not enough stock</exception>
        private async Task ValidateStockAvailabilityAsync(ProductSize productSize, int requestedQuantity)
        {
            // Get the latest stock information
            var latestStock = await _context.ProductSizes
                .Include(ps => ps.Product)
                .Include(ps => ps.Size)
                .FirstOrDefaultAsync(ps => ps.Id == productSize.Id);

            if (latestStock == null)
            {
                throw new UserException($"Veličina proizvoda sa ID {productSize.Id} više ne postoji", (int)HttpStatusCode.NotFound);
            }

            if (latestStock.Quantity < requestedQuantity)
            {
                throw new UserException($"Nema dovoljno zaliha za proizvod '{latestStock.Product?.Name}' u veličini '{latestStock.Size?.Name}'. Dostupno: {latestStock.Quantity}", (int)HttpStatusCode.BadRequest);
            }

            await Task.CompletedTask;
        }

        /// <summary>
        /// Validates that there's enough stock for a product size
        /// </summary>
        /// <param name="productSizeId">The ID of the product size to check</param>
        /// <param name="requestedQuantity">The requested quantity</param>
        /// <exception cref="UserException">Thrown if there's not enough stock</exception>
        private async Task ValidateStockAvailabilityAsync(int productSizeId, int requestedQuantity)
        {
            var productSize = await _context.ProductSizes
                .Include(ps => ps.Product)
                .Include(ps => ps.Size)
                .FirstOrDefaultAsync(ps => ps.Id == productSizeId);

            if (productSize == null)
            {
                throw new UserException($"Veličina proizvoda sa ID {productSizeId} nije pronađena", (int)HttpStatusCode.NotFound);
            }

            await ValidateStockAvailabilityAsync(productSize, requestedQuantity);
        }

        #endregion

        /// <summary>
        /// Private helper method to get a cart with all its related data by cart ID
        /// </summary>
        /// <param name="cartId">The ID of the cart to retrieve</param>
        /// <returns>The cart with all related data, or null if not found</returns>
        /// <remarks>
        /// This method loads the cart with user info, items, product sizes, products, and sizes.
        /// It's used internally to reload a cart after modifications to ensure all relations are loaded.
        /// </remarks>
        private async Task<CartResponse> GetFullCartAsync(int cartId)
        {
            var cart = await _context.Carts
                .AsNoTracking()
                .Include(c => c.User)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(x => x.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(c => c.Id == cartId);

            if (cart == null)
                return null;

            return MapToResponse(cart);
        }

        /// <summary>
        /// Maps a Cart entity to a CartResponse object
        /// </summary>
        /// <param name="entity">The Cart entity to map</param>
        /// <returns>A CartResponse object with all cart data mapped</returns>
        /// <remarks>
        /// This method:
        /// 1. Maps the base properties using Mapster
        /// 2. Calculates the total amount
        /// 3. Maps user information
        /// 4. Maps each cart item with its product information
        /// </remarks>
        private CartResponse MapToResponse(Database.Cart entity)
        {
            var response = _mapper.Map<CartResponse>(entity);
            
            // Calculate total amount
            response.TotalAmount = entity.TotalAmount;
            
            // Map user info
            if (entity.User != null)
            {
                response.UserFullName = $"{entity.User.FirstName} {entity.User.LastName}";
            }
            
            // Map cart items
            if (entity.Items != null)
            {
                response.Items = entity.Items.Select(item => new CartItemResponse
                {
                    Id = item.Id,
                    CartId = item.CartId,
                    ProductSizeId = item.ProductSizeId,
                    ProductName = item.ProductSize?.Product?.Name ?? "Nepoznat Proizvod",
                    SizeName = item.ProductSize?.Size?.Name ?? "Nepoznata Veličina",
                    Price = item.ProductSize?.Product?.Price ?? 0,
                    ImageUrl = item.ProductSize?.Product?.ProductAssets?.FirstOrDefault()?.Asset?.Url ?? "",
                    Quantity = item.Quantity,
                    AddedAt = item.AddedAt,
                    Subtotal = item.Subtotal
                }).ToList();
            }
            
            return response;
        }
    }
} 