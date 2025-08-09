using System;
using System.Threading.Tasks;
using MyClub.Model;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using MapsterMapper;

namespace MyClub.Services.OrderStateMachine
{
    public class BaseOrderState
    {
        protected readonly IServiceProvider _serviceProvider;
        protected readonly MyClubContext _context;
        protected readonly IMapper _mapper;
        protected readonly IRabbitMQService _rabbitMQService;

        public BaseOrderState(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
            _context = _serviceProvider.GetRequiredService<MyClubContext>();
            _mapper = _serviceProvider.GetRequiredService<IMapper>();
            _rabbitMQService = _serviceProvider.GetRequiredService<IRabbitMQService>();
        }
        public virtual async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            throw new UserException("Action not allowed");
        }
        public virtual async Task<OrderResponse> ConfirmOrder(ConfirmOrderRequest request)
        {
            throw new UserException("Action not allowed");
        }
        public virtual async Task<PaymentResponse> PlaceOrder(OrderInsertRequest request)
        {
            throw new UserException("Action not allowed");
        }
        public BaseOrderState GetOrderState(string stateName)
        {
            switch (stateName)
            {
                case "Iniciranje":
                    return _serviceProvider.GetService<InitialOrderState>();
                case "Procesiranje":
                    return _serviceProvider.GetService<ProcessingOrderState>();
                case "Potvrđeno":
                    return _serviceProvider.GetService<ConfirmedOrderState>();
                case "Otkazano":
                    return _serviceProvider.GetService<CancelledOrderState>();
                case "Dostava":
                    return _serviceProvider.GetService<DeliveryOrderState>();
                case "Završeno":
                    return _serviceProvider.GetService<FinishedOrderState>();
                default:
                    throw new UserException($"Unknown order state: {stateName}");
            }
        }
        protected async Task<OrderResponse> MapOrderToResponse(Order entity)
        {
            if (entity == null)
                return null;

            // If we only have the ID, load the complete order with all relationships
            if (entity.ShippingDetails == null || entity.User == null || entity.OrderItems == null)
            {
                // Load a fresh copy with all includes to ensure we have everything
                var refreshedOrder = await _context.Orders
                    .Include(o => o.User)
                    .Include(o => o.Payment)
                    .Include(o => o.ShippingDetails)
                    .ThenInclude(s => s.City)
                    .ThenInclude(c => c.Country)
                    .Include(o => o.OrderItems)
                        .ThenInclude(i => i.ProductSize)
                            .ThenInclude(ps => ps.Product)
                    .Include(o => o.OrderItems)
                        .ThenInclude(i => i.ProductSize)
                            .ThenInclude(ps => ps.Size)
                    .FirstOrDefaultAsync(o => o.Id == entity.Id);

                if (refreshedOrder != null)
                {
                    entity = refreshedOrder;
                }
            }

            var response = _mapper.Map<OrderResponse>(entity);

            // Safely map user full name
            if (entity.User != null)
            {
                response.UserFullName = entity.User.FirstName + " " + entity.User.LastName;
            }

            // Check if shipping details are mapped
            Console.WriteLine($"DEBUG: ShippingDetailsId: {entity.ShippingDetailsId}, ShippingDetails: {entity.ShippingDetails != null}");

            // Map shipping details if available
            if (entity.ShippingDetails != null)
            {
                response.ShippingAddress = entity.ShippingDetails.ShippingAddress;

                // Map City and Country if available
                if (entity.ShippingDetails.City != null)
                {
                    // Create and assign the ShippingCity object
                    response.ShippingCity = new Model.Responses.CityResponse
                    {
                        Id = entity.ShippingDetails.City.Id,
                        Name = entity.ShippingDetails.City.Name,
                        PostalCode = entity.ShippingDetails.City.PostalCode,
                    };

                    // Map Country from City if available
                    if (entity.ShippingDetails.City.Country != null)
                    {
                        response.ShippingCity.Country = new Model.Responses.CountryResponse
                        {
                            Id = entity.ShippingDetails.City.Country.Id,
                            Name = entity.ShippingDetails.City.Country.Name,
                            Code = entity.ShippingDetails.City.Country.Code
                        };
                    }

                    // For debugging purposes
                    Console.WriteLine($"DEBUG: Mapped shipping details - Address: {response.ShippingAddress}, City: {response.ShippingCity.Name}");
                }
            }
            else
            {
                Console.WriteLine("DEBUG: ShippingDetails is null after loading!");
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
        
        protected void SendOrderStateChangeEmail(Order order, string oldState)
        {
            Console.WriteLine($"DEBUG: SendOrderStateChangeEmail called for order {order?.Id}, old state: {oldState}, new state: {order?.OrderState}");
            
            if (order?.User == null)
            {
                Console.WriteLine($"DEBUG: Cannot send email - order.User is null for order {order?.Id}");
                return;
            }

            if (string.IsNullOrEmpty(order.User.Email))
            {
                Console.WriteLine($"DEBUG: Cannot send email - order.User.Email is empty for order {order.Id}");
                return;
            }

            string subject = $"Promjena stanja narudžbe #{order.Id}";
            string body = $"Poštovani {order.User.FirstName},\n\nVaša narudžba #{order.Id} je promijenila stanje iz '{oldState}' u '{order.OrderState}'.\n\n";
            
            // Add specific messages based on the new state
            switch (order.OrderState)
            {
                case "Iniciranje":
                    body += "Vaša narudžba je započeta. Molimo dovršite proces naplate kako bismo mogli procesirati vašu narudžbu.\n\n";
                    break;
                case "Procesiranje":
                    body += "Vaša narudžba je trenutno u obradi. Uskoro ćemo potvrditi sve detalje.\n\n";
                    break;
                case "Potvrđeno":
                    body += "Vaša narudžba je potvrđena i bit će uskoro spremna za dostavu.\n\n";
                    break;
                case "Otkazano":
                    body += "Vaša narudžba je otkazana. Ako imate pitanja, molimo kontaktirajte našu podršku.\n\n";
                    break;
                case "Dostava":
                    body += "Vaša narudžba je poslana na dostavu i uskoro bi trebala stići na vašu adresu.\n\n";
                    break;
                case "Završeno":
                    body += "Vaša narudžba je uspješno isporučena. Hvala vam na kupovini!\n\n";
                    break;
                default:
                    body += "Status vaše narudžbe je promijenjen. Za više informacija, posjetite svoj korisnički račun.\n\n";
                    break;
            }
            
            body += "Hvala na povjerenju,\nMyClub tim";
            
            var emailMessage = new EmailMessage
            {
                To = order.User.Email,
                Subject = subject,
                Body = body,
                OrderId = order.Id,
                OrderState = order.OrderState
            };
            
            Console.WriteLine($"DEBUG: Sending email message to {emailMessage.To} with subject '{emailMessage.Subject}'");
            try 
            {
                _rabbitMQService.SendMessage("order_notifications", emailMessage);
                Console.WriteLine($"DEBUG: Email message sent to RabbitMQ successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR: Failed to send email via RabbitMQ: {ex.Message}");
            }
        }

    }
}