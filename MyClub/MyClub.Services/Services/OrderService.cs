using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Helpers;
using MyClub.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MyClub.Services.OrderStateMachine;

namespace MyClub.Services.Services
{
    public class OrderService : BaseService<OrderResponse, OrderSearchObject, Database.Order>, IOrderService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IUserService _userService;
        private readonly IPaymentService _paymentService;
        private readonly MyClubContext _context;

        protected readonly BaseOrderState _baseOrderState;

        public OrderService(
            MyClubContext context,
            IMapper mapper,
            IHttpContextAccessor httpContextAccessor,
            IUserService userService,
            IPaymentService paymentService,
            BaseOrderState baseOrderState)
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
            _userService = userService;
            _paymentService = paymentService;
            _context = context;
            _baseOrderState = baseOrderState;
        }


        public override async Task<PagedResult<OrderResponse>> GetAsync(OrderSearchObject search)
        {
            var query = _context.Set<Database.Order>().AsQueryable();

            // Add necessary includes
            query = query.Include(x => x.OrderItems)
                .ThenInclude(x => x.ProductSize)
                .ThenInclude(x => x.Product)
                .Include(x => x.OrderItems)
                .ThenInclude(x => x.ProductSize)
                .ThenInclude(x => x.Size)
                .Include(x => x.User)
                .Include(x => x.Payment)
                .Include(x => x.ShippingDetails)
                .ThenInclude(s => s.City)
                .ThenInclude(c => c.Country);

            // Apply filters
            query = ApplyFilter(query, search);

            // Get total count before pagination
            int totalCount = 0;
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

            return new PagedResult<OrderResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        public override async Task<OrderResponse> GetByIdAsync(int id)
        {
            var order = await _context.Orders
            .Include(x => x.OrderItems)
            .ThenInclude(x => x.ProductSize)
            .ThenInclude(x => x.Product)
            .Include(x => x.User)
            .Include(x => x.Payment)
            .Include(x => x.ShippingDetails)
            .ThenInclude(s => s.City)
            .ThenInclude(c => c.Country)
            .FirstOrDefaultAsync(x => x.Id == id);
            if (order == null)
            {
                throw new KeyNotFoundException($"Order with ID {id} not found");
            }
            return MapToResponse(order);
        }

        protected override IQueryable<Database.Order> ApplyFilter(IQueryable<Database.Order> query, OrderSearchObject search)
        {
            if (search?.UserId != null)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }
            return query;
        }

        protected override OrderResponse MapToResponse(Database.Order entity)
        {
            if (entity == null)
                return null;

            var response = base.MapToResponse(entity);

            // Safely map user full name
            if (entity.User != null)
            {
                response.UserFullName = entity.User.FirstName + " " + entity.User.LastName;
            }

            // Map shipping details if available
            if (entity.ShippingDetails != null)
            {
                response.ShippingAddress = entity.ShippingDetails.ShippingAddress;

                // Map City and Country if available
                if (entity.ShippingDetails.City != null)
                {
                    // Create and assign the ShippingCity object
                    response.ShippingCity = new CityResponse
                    {
                        Id = entity.ShippingDetails.City.Id,
                        Name = entity.ShippingDetails.City.Name,
                        PostalCode = entity.ShippingDetails.City.PostalCode,
                    };

                    // Map Country from City if available
                    if (entity.ShippingDetails.City.Country != null)
                    {
                        response.ShippingCity.Country = new CountryResponse
                        {
                            Id = entity.ShippingDetails.City.Country.Id,
                            Name = entity.ShippingDetails.City.Country.Name,
                            Code = entity.ShippingDetails.City.Country.Code
                        };
                    }
                }
            }

            // Calculate if membership discount was applied (20% less than sum of order items)
            decimal itemsTotal = 0;
            if (entity.OrderItems != null)
            {
                foreach (var item in entity.OrderItems)
                {
                    if (item?.ProductSize?.Product != null)
                    {
                        itemsTotal += item.ProductSize.Product.Price * item.Quantity;
                    }
                }
            }

            // Check if a membership discount was applied (20%)
            response.OriginalAmount = itemsTotal;
            response.HasMembershipDiscount = itemsTotal > entity.TotalAmount;

            if (response.HasMembershipDiscount)
            {
                response.DiscountAmount = itemsTotal - entity.TotalAmount;
            }
            else
            {
                response.DiscountAmount = 0;
            }

            // Map payment method if available
            if (entity.Payment != null)
            {
                response.PaymentMethod = entity.Payment.Method;
            }

            // Map order items
            if (entity.OrderItems != null)
            {
                response.OrderItems = entity.OrderItems.Select(item => new OrderItemResponse
                {
                    Id = item.Id,
                    OrderId = item.OrderId,
                    ProductSizeId = item.ProductSizeId,
                    Quantity = item.Quantity,
                    UnitPrice = item.UnitPrice,
                    ProductName = item.ProductSize?.Product?.Name,
                    SizeName = item.ProductSize?.Size?.Name,
                    Subtotal = item.UnitPrice * item.Quantity
                }).ToList();
            }
            else
            {
                response.OrderItems = new List<OrderItemResponse>();
            }

            return response;
        }

        public async Task<PaymentResponse> PlaceOrder(OrderInsertRequest request)
        {
            var baseOrderState = _baseOrderState.GetOrderState("Iniciranje");
            var result = await baseOrderState.PlaceOrder(request);
            return result;
        }
        public async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            var entity = await _context.Orders.FindAsync(orderId);

            var orderState = _baseOrderState.GetOrderState(entity.OrderState);

            return await orderState.ChangeOrderState(orderId, request);

        }
        public async Task<OrderResponse> ConfirmOrder(ConfirmOrderRequest request)
        {
            var baseOrderState = _baseOrderState.GetOrderState("Iniciranje");
            var result = await baseOrderState.ConfirmOrder(request);
            return result;
        }


        public async Task<PagedResult<OrderResponse>> GetUserOrdersAsync(int userId)
        {
            var query = _context.Orders
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.ProductSize)
                        .ThenInclude(ps => ps.Product)
                .Include(o => o.User)
                .Where(o => o.UserId == userId);

                

            var totalCount = await query.CountAsync();

            var orders = await query.ToListAsync();

            var responses = orders.Select(MapToResponse).ToList();

            return new PagedResult<OrderResponse>
            {
                Data = responses,
                TotalCount = totalCount,
                CurrentPage = 0,
                PageSize = totalCount // Return all results
            };
        }
    }
}