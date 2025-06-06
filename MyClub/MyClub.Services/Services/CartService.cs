using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;
using System;

namespace MyClub.Services
{
    public class CartService : BaseCRUDService<CartResponse, CartSearchObject, CartUpsertRequest, CartUpsertRequest, Database.Cart>, ICartService
    {
        private readonly MyClubContext _context;

        public CartService(MyClubContext context, IMapper mapper) 
            : base(context, mapper)
        {
            _context = context;
        }

        public override async Task<PagedResult<CartResponse>> GetAsync(CartSearchObject search)
        {
            var query = _context.Carts
                .AsNoTracking()
                .Include(c => c.User)
                .AsQueryable();

            // Apply filters
            query = ApplyFilter(query, search);

            // Include items if requested
            if (search.IncludeItems == true)
            {
                query = query.Include(c => c.Items)
                    .ThenInclude(i => i.ProductSize)
                    .ThenInclude(ps => ps.Product);
            }

            int totalCount = 0;
            
            // Get total count if requested
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;
            
            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();
            
            // Create the paged result
            return new PagedResult<CartResponse>
            {
                Data = list.Select(x => MapToResponse(x)).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        public override async Task<CartResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Carts
                .AsNoTracking()
                .Include(c => c.User)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Product)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public async Task<CartResponse> GetCartByUserIdAsync(int userId)
        {
            var cart = await _context.Carts
                .AsNoTracking()
                .Include(c => c.User)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Product)
                .Include(c => c.Items)
                .ThenInclude(i => i.ProductSize)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                // Create a new cart for the user
                var newCart = new Database.Cart
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow
                };
                
                _context.Carts.Add(newCart);
                await _context.SaveChangesAsync();
                
                // Reload with user information
                cart = await _context.Carts
                    .Include(c => c.User)
                    .FirstOrDefaultAsync(c => c.Id == newCart.Id);
            }

            return MapToResponse(cart);
        }

        public async Task<CartResponse> AddItemAsync(int cartId, CartItemUpsertRequest request)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == cartId);

            if (cart == null)
                throw new Exception($"Cart with ID {cartId} not found");

            // Check if the product size exists
            var productSize = await _context.ProductSizes
                .Include(ps => ps.Product)
                .FirstOrDefaultAsync(ps => ps.Id == request.ProductSizeId);

            if (productSize == null)
                throw new Exception($"ProductSize with ID {request.ProductSizeId} not found");

            // Check if there's enough stock
            if (productSize.Quantity < request.Quantity)
                throw new Exception($"Not enough stock. Available: {productSize.Quantity}");

            // Check if the item already exists in the cart
            var existingItem = cart.Items.FirstOrDefault(i => i.ProductSizeId == request.ProductSizeId);

            if (existingItem != null)
            {
                // Update the quantity of the existing item
                existingItem.Quantity += request.Quantity;
                
                // Check if the new quantity exceeds the stock
                if (existingItem.Quantity > productSize.Quantity)
                    throw new Exception($"Not enough stock. Available: {productSize.Quantity}");
            }
            else
            {
                // Add a new item to the cart
                var newItem = new CartItem
                {
                    CartId = cartId,
                    ProductSizeId = request.ProductSizeId,
                    Quantity = request.Quantity,
                    AddedAt = DateTime.UtcNow
                };
                
                cart.Items.Add(newItem);
            }

            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data
            return await GetByIdAsync(cartId);
        }

        public async Task<CartResponse> UpdateItemAsync(int cartId, int itemId, CartItemUpsertRequest request)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == cartId);

            if (cart == null)
                throw new Exception($"Cart with ID {cartId} not found");

            var cartItem = cart.Items.FirstOrDefault(i => i.Id == itemId);

            if (cartItem == null)
                throw new Exception($"Cart item with ID {itemId} not found in cart {cartId}");

            // Check if the product size exists
            var productSize = await _context.ProductSizes
                .Include(ps => ps.Product)
                .FirstOrDefaultAsync(ps => ps.Id == request.ProductSizeId);

            if (productSize == null)
                throw new Exception($"ProductSize with ID {request.ProductSizeId} not found");

            // Check if there's enough stock
            if (productSize.Quantity < request.Quantity)
                throw new Exception($"Not enough stock. Available: {productSize.Quantity}");

            // Update the cart item
            cartItem.ProductSizeId = request.ProductSizeId;
            cartItem.Quantity = request.Quantity;
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data
            return await GetByIdAsync(cartId);
        }

        public async Task<CartResponse> RemoveItemAsync(int cartId, int itemId)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == cartId);

            if (cart == null)
                throw new Exception($"Cart with ID {cartId} not found");

            var cartItem = cart.Items.FirstOrDefault(i => i.Id == itemId);

            if (cartItem == null)
                throw new Exception($"Cart item with ID {itemId} not found in cart {cartId}");

            // Remove the item from the cart
            cart.Items.Remove(cartItem);
            _context.CartItems.Remove(cartItem);
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Reload the cart with all related data
            return await GetByIdAsync(cartId);
        }

        public async Task<CartResponse> ClearCartAsync(int cartId)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == cartId);

            if (cart == null)
                throw new Exception($"Cart with ID {cartId} not found");

            // Remove all items from the cart
            _context.CartItems.RemoveRange(cart.Items);
            cart.Items.Clear();
            
            // Update the cart's UpdatedAt timestamp
            cart.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            // Return the empty cart
            return MapToResponse(cart);
        }

        protected override IQueryable<Database.Cart> ApplyFilter(IQueryable<Database.Cart> query, CartSearchObject search)
        {
            // Filter by user ID
            if (search.UserId.HasValue)
            {
                query = query.Where(c => c.UserId == search.UserId.Value);
            }

            // Filter by date range
            if (search.FromDate.HasValue)
            {
                query = query.Where(c => c.CreatedAt >= search.FromDate.Value);
            }

            if (search.ToDate.HasValue)
            {
                query = query.Where(c => c.CreatedAt <= search.ToDate.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.Cart entity, CartUpsertRequest request)
        {
            // Check if the user exists
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new Exception($"User with ID {request.UserId} not found");

            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(Database.Cart entity, CartUpsertRequest request)
        {
            // Check if the user exists
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new Exception($"User with ID {request.UserId} not found");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override Database.Cart MapInsertToEntity(Database.Cart entity, CartUpsertRequest request)
        {
            entity = _mapper.Map(request, entity);
            
            // Map cart items separately
            if (request.Items != null && request.Items.Any())
            {
                entity.Items = request.Items.Select(item => new CartItem
                {
                    ProductSizeId = item.ProductSizeId,
                    Quantity = item.Quantity,
                    AddedAt = DateTime.UtcNow
                }).ToList();
            }
            
            return entity;
        }

        protected override Database.Cart MapUpdateToEntity(Database.Cart entity, CartUpsertRequest request)
        {
            entity = _mapper.Map(request, entity);
            
            // Handle cart items update separately in specific methods
            
            return entity;
        }

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
                    ProductName = item.ProductSize?.Product?.Name ?? "Unknown Product",
                    SizeName = item.ProductSize?.Size?.Name ?? "Unknown Size",
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