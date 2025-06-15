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
            
            // If the total amount is approximately 20% less than the items total, a discount was applied
            decimal expectedDiscountedAmount = Math.Round(itemsTotal * (1 - DiscountHelper.MEMBERSHIP_DISCOUNT_PERCENTAGE), 2);
            response.HasMembershipDiscount = Math.Abs(entity.TotalAmount - expectedDiscountedAmount) < 0.1m;
            response.OriginalAmount = response.HasMembershipDiscount ? itemsTotal : entity.TotalAmount;
            response.DiscountAmount = response.HasMembershipDiscount ? (itemsTotal - entity.TotalAmount) : 0;
            
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
            
            // Check if user has active membership for discount
            bool hasActiveMembership = await DiscountHelper.HasActiveUserMembership(_context, userId);
            
            // Verify the total amount if user has a discount
            decimal calculatedTotal = 0;
            foreach (var item in request.Items)
            {
                var productSize = await _context.ProductSizes
                    .Include(ps => ps.Product)
                    .FirstOrDefaultAsync(ps => ps.Id == item.ProductSizeId);
                
                if (productSize == null)
                {
                    throw new KeyNotFoundException($"ProductSize with ID {item.ProductSizeId} not found");
                }
                
                calculatedTotal += productSize.Product.Price * item.Quantity;
            }
            
            // Apply discount if applicable
            decimal finalTotal = hasActiveMembership 
                ? Math.Round(calculatedTotal * (1 - DiscountHelper.MEMBERSHIP_DISCOUNT_PERCENTAGE), 2) 
                : calculatedTotal;
            
            // Validate total amount (allowing small difference for rounding errors)
            if (Math.Abs(finalTotal - request.TotalAmount) > 0.1m)
            {
                throw new InvalidOperationException($"Total amount mismatch. Expected: {finalTotal}, Received: {request.TotalAmount}");
            }

            // Create shipping details
            var shippingDetails = new ShippingDetails
            {
                ShippingAddress = request.ShippingAddress,
                ShippingCity = request.ShippingCity,
                ShippingPostalCode = request.ShippingPostalCode,
                ShippingCountry = request.ShippingCountry
            };
            _context.Set<ShippingDetails>().Add(shippingDetails);
            await _context.SaveChangesAsync();

            // Create payment
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                Amount = request.TotalAmount,
                Method = request.PaymentMethod,
                Status = "Completed",
                CreatedAt = DateTime.UtcNow,
                CompletedAt = DateTime.UtcNow
            };
            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            var order = new Database.Order(){
                OrderNumber = Guid.NewGuid().ToString(),
                UserId = userId,
                OrderDate = DateTime.UtcNow,
                Status = Database.OrderStatus.Pending.ToString(),
                TotalAmount = request.TotalAmount,
                ShippingDetailsId = shippingDetails.Id,
                PaymentMethod = request.PaymentMethod,
                PaymentId = payment.Id,
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

            return MapToResponse(order);
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