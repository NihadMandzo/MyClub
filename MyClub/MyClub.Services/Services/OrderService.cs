using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace MyClub.Services.Services
{
    public class OrderService : BaseService<OrderResponse, OrderSearchObject, Database.Order>, IOrderService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IUserService _userService;
        private readonly IPaymentService _paymentService;
        private readonly MyClubContext _context;

        public OrderService(
            MyClubContext context, 
            IMapper mapper, 
            IHttpContextAccessor httpContextAccessor,
            IUserService userService,
            IPaymentService paymentService) 
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
            _userService = userService;
            _paymentService = paymentService;
            _context = context;
        }


        protected override IQueryable<Database.Order> ApplyFilter(IQueryable<Database.Order> query, OrderSearchObject search)
        {
            if (search?.UserId != null)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }
            if (search?.Status != null)
            {
                query = query.Where(x => x.Status.ToString() == search.Status.Value.ToString());
            }
            if (search?.OrderNumber != null)
            {
                query = query.Where(x => x.OrderNumber == search.OrderNumber);
            }
            return query;
        }

        protected override OrderResponse MapToResponse(Database.Order entity)
        {
            var response = base.MapToResponse(entity);
            response.UserFullName = entity.User.FirstName + " " + entity.User.LastName;
            return response;
        }

        public async Task<OrderResponse> PlaceOrder(OrderInsertRequest request)
        {
            var userId = int.Parse(_httpContextAccessor.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value);
            var user = await _userService.GetByIdAsync(userId);
            if (user == null)
            {
                throw new KeyNotFoundException($"User with ID {userId} not found");
            }

            var order = new Database.Order(){
                OrderNumber = Guid.NewGuid().ToString(),
                UserId = userId,
                OrderDate = DateTime.UtcNow,
                Status = Database.OrderStatus.Pending.ToString(),
                TotalAmount = request.TotalAmount,
                ShippingAddress = request.ShippingAddress,
                PaymentMethod = request.PaymentMethod,
                ShippedDate = null,
                DeliveredDate = null,
                Notes = request.Notes,
                OrderItems = request.Items.Select(x => new Database.OrderItem(){
                    ProductSizeId = x.ProductSizeId,
                    Quantity = x.Quantity,
                }).ToList()
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            return null;
        }

        public async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(x => x.Id == orderId);
            if (order == null)
            {
                throw new KeyNotFoundException($"Order with ID {orderId} not found");
            }
            order.Status = request.NewStatus.ToString();
            await _context.SaveChangesAsync();

            return MapToResponse(order);
        }
    }
} 