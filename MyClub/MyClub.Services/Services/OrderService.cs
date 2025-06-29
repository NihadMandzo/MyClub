using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
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

            // Map shipping details if available
            if (entity.ShippingDetails != null)
            {
                response.ShippingAddress = entity.ShippingDetails.ShippingAddress;
                response.ShippingCity = entity.ShippingDetails.ShippingCity;
                response.ShippingPostalCode = entity.ShippingDetails.ShippingPostalCode;
                response.ShippingCountry = entity.ShippingDetails.ShippingCountry;
            }

            // Calculate if membership discount was applied (20% less than sum of order items)
            decimal itemsTotal = 0;
            foreach (var item in entity.OrderItems)
            {
                if (item.ProductSize?.Product != null)
                {
                    itemsTotal += item.ProductSize.Product.Price * item.Quantity;
                }
            }


            return response;
        }

        public async Task<PaymentResponse> PlaceOrder(OrderInsertRequest request)
        {
            var payment = await _paymentService.CreateStripePaymentAsync(request);
            return payment;
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
        public async Task<OrderResponse> ConfirmOrder(ConfirmOrderRequest request)
        {
            var userId = JwtTokenManager.GetUserIdFromToken(_httpContextAccessor.HttpContext.Request.Headers["Authorization"].ToString());
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                throw new KeyNotFoundException($"User with ID {userId} not found");
            }


            var payment = await _paymentService.ConfirmStripePayment(request.TransactionId);
            if (!payment)
            {
                throw new Exception("Payment failed");
            }
            
            
            var shippingDetails = new ShippingDetails
            {
                ShippingAddress = request.ShippingAddress,
                ShippingCity = request.ShippingCity,
                ShippingPostalCode = request.ShippingPostalCode,
                ShippingCountry = request.ShippingCountry,
            };
            await _context.ShippingDetails.AddAsync(shippingDetails);
            await _context.SaveChangesAsync();

            var order = new Order
            {
                UserId = userId,
                Status = "Pending",
                TotalAmount = request.Amount,
                ShippingDetailsId = shippingDetails.Id
            };
            await _context.Orders.AddAsync(order);
            await _context.SaveChangesAsync();

            var orderItems = new List<OrderItem>();
            foreach (var item in request.Items)
            {
                var orderItem = new OrderItem
                {
                    ProductSizeId = item.ProductSizeId,
                    Quantity = item.Quantity,
                    UnitPrice = item.UnitPrice,
                    OrderId = order.Id
                };
                await _context.OrderItems.AddAsync(orderItem);
            }

            await _context.SaveChangesAsync();
            return MapToResponse(order);
        }
    }
}