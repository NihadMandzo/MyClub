using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model.SearchObjects;
using MapsterMapper;
using Microsoft.EntityFrameworkCore.Metadata;
using MyClub.Services.Helpers;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace MyClub.Services.OrderStateMachine
{
    public class InitialOrderState : BaseOrderState
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IPaymentService _paymentService;
        private readonly MyClubContext _context;

        private readonly IServiceProvider _serviceProvider;
        public InitialOrderState(IServiceProvider serviceProvider,
            IHttpContextAccessor httpContextAccessor,
            IPaymentService paymentService, MyClubContext context)
            : base(serviceProvider)
        {
            _httpContextAccessor = httpContextAccessor;
            _paymentService = paymentService;
            _serviceProvider = serviceProvider;
            _context = context;
        }

        public override async Task<OrderResponse> ConfirmOrder(ConfirmOrderRequest request)
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

            
            var order = await _context.Orders
                                .Include(x => x.Payment)
                                .Include(x => x.OrderItems)
                                .ThenInclude(x => x.ProductSize)
                                .ThenInclude(x => x.Product)
                                .Include(x => x.User)
                                .Include(x => x.ShippingDetails)
                                .FirstOrDefaultAsync(x => x.Payment.TransactionId.Contains(request.TransactionId));
            if (order == null)
            {
                throw new KeyNotFoundException($"Order with TransactionId {request.TransactionId} not found");
            }
            var oldState = order.OrderState;
            order.OrderState = "Procesiranje";
            order.Payment.Status = "Completed";
            order.Payment.CompletedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            // Send message to RabbitMQ
            base.SendOrderStateChangeEmail(order, oldState);
            return await MapOrderToResponse(order);
        }
        public override async Task<PaymentResponse> PlaceOrder(OrderInsertRequest request)
        {
            try
            {
                // 1. Check if products are in stock
                foreach (var item in request.Items)
                {
                    var productSize = await _context.ProductSizes
                        .Where(ps => ps.Id == item.ProductSizeId)
                        .FirstOrDefaultAsync();

                    if (productSize == null || productSize.Quantity < item.Quantity)
                    {
                        throw new UserException("Product is out of stock");
                    }
                }

                // 2. Create shipping details first
                // First find the City by name
                var city = await _context.Cities
                    .Include(c => c.Country)
                    .FirstOrDefaultAsync(c => c.Id==request.Shipping.CityId);
                    
                if (city == null)
                {
                    throw new UserException($"City '{request.Shipping.CityId}' not found.");
                }

                var shippingDetails = new ShippingDetails
                {
                    ShippingAddress = request.Shipping.ShippingAddress,
                    CityId=request.Shipping.CityId
                };

                _context.ShippingDetails.Add(shippingDetails);
                await _context.SaveChangesAsync(); // Save to get ShippingDetails ID

                // 3. Create new order
                var order = new Order
                {
                    UserId = request.UserId,
                    OrderDate = DateTime.Now,
                    OrderState = "Iniciranje",
                    TotalAmount = request.Amount,
                    Notes = request.Notes,
                    ShippingDetailsId = shippingDetails.Id
                };
                

                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .FirstOrDefaultAsync(c => c.UserId == request.UserId);

                foreach (var cartItem in cart.Items)
                {
                    _context.CartItems.Remove(cartItem);
                }
                _context.Carts.Remove(cart);
                _context.Orders.Add(order);
                await _context.SaveChangesAsync(); // Save to get Order ID

                // 4. Create order items
                foreach (var itemRequest in request.Items)
                {
                    var productSize = await _context.ProductSizes
                        .Include(ps => ps.Product)
                        .FirstOrDefaultAsync(ps => ps.Id == itemRequest.ProductSizeId);

                    var orderItem = new OrderItem
                    {
                        OrderId = order.Id,
                        ProductSizeId = itemRequest.ProductSizeId,
                        Quantity = itemRequest.Quantity,
                        UnitPrice = itemRequest.UnitPrice
                    };

                    // Update stock
                    productSize.Quantity -= itemRequest.Quantity;

                    _context.OrderItems.Add(orderItem);
                }

                await _context.SaveChangesAsync();

                // 5. Create payment based on type
                PaymentResponse paymentResponse = null;

                if (request.Type.Equals("Stripe", StringComparison.OrdinalIgnoreCase))
                {
                    // Create payment in Stripe
                    paymentResponse = await _paymentService.CreateStripePaymentAsync(request);
                }
                else if (request.Type.Equals("PayPal", StringComparison.OrdinalIgnoreCase))
                {
                    // Create payment in PayPal (returns URL string, not PaymentResponse)
                    var paypalUrl = await _paymentService.CreatePayPalPaymentAsync(request);
                    paymentResponse = new PaymentResponse
                    {
                        transactionId = Guid.NewGuid().ToString(),
                        clientSecret = paypalUrl
                    };
                }

                // 6. Create payment record in database
                var payment = new Payment
                {
                    OrderId = order.Id,
                    Amount = request.Amount,
                    Method = request.Type,
                    TransactionId = paymentResponse.transactionId,
                    Status = "Pending",
                    CreatedAt = DateTime.Now
                };

                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();

                // 7. Update order with payment ID
                order.PaymentId = payment.Id;
                await _context.SaveChangesAsync();

                return paymentResponse;
            }
            catch (Exception ex)
            {
                throw new UserException($"Error placing order: {ex.Message}", 500);
            }
        }
  }
}
