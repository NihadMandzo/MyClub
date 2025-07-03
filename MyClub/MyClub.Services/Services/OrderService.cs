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
                .Include(x => x.ShippingDetails);
                
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
            if (search?.Status != null)
            {
                query = query.Where(x => x.Status.ToString() == search.Status.Value.ToString());
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
                response.ShippingCity = entity.ShippingDetails.ShippingCity;
                response.ShippingPostalCode = entity.ShippingDetails.ShippingPostalCode;
                response.ShippingCountry = entity.ShippingDetails.ShippingCountry;
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
            var userId = JwtTokenManager.GetUserIdFromToken(_httpContextAccessor.HttpContext.Request.Headers["Authorization"].ToString());
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                throw new KeyNotFoundException($"User with ID {userId} not found");
            }
            var payment = await _paymentService.CreateStripePaymentAsync(request);
            
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
                Status = Database.OrderStatus.Pending,
                TotalAmount = request.Amount,
                ShippingDetailsId = shippingDetails.Id,
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


            var paymentEntity = new Payment
            {
                TransactionId = payment.transactionId,
                Amount = request.Amount,
                Status = "Pending",
                Method = "Stripe",
                CreatedAt = DateTime.UtcNow,
            };
            await _context.Payments.AddAsync(paymentEntity);
            await _context.SaveChangesAsync();
            order.PaymentId = paymentEntity.Id;
            await _context.SaveChangesAsync();
            return payment??throw new UserException("Payment failed");
        }
        public async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            var order = await _context.Orders
                                .Include(x => x.Payment)
                                .Include(x => x.OrderItems)
                                .ThenInclude(x => x.ProductSize)
                                .ThenInclude(x => x.Product)
                                .Include(x => x.User)
                                .Include(x => x.ShippingDetails)
                                .FirstOrDefaultAsync(x => x.Id == orderId);
            if (order == null)
            {
                throw new KeyNotFoundException($"Order with ID {orderId} not found");
            }
            order.Status = (Database.OrderStatus)request.NewStatus;
            await _context.SaveChangesAsync();

            return MapToResponse(order);
        }
        private async Task AfterConfirmedOrder(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null)
            {
                throw new KeyNotFoundException($"Order with ID {orderId} not found");
            }
            order.Status = Database.OrderStatus.Processing;
            await _context.SaveChangesAsync();
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
                await AfterConfirmedOrder(order.Id);
                return MapToResponse(order);
        }
    }
}