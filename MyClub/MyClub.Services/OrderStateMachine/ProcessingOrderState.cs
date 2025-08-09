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
    public class ProcessingOrderState : BaseOrderState
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IPaymentService _paymentService;
        private readonly MyClubContext _context;

        private readonly IServiceProvider _serviceProvider;
        public ProcessingOrderState(IServiceProvider serviceProvider,
            IHttpContextAccessor httpContextAccessor,
            IPaymentService paymentService, MyClubContext context)
            : base(serviceProvider)
        {
            _httpContextAccessor = httpContextAccessor;
            _paymentService = paymentService;
            _serviceProvider = serviceProvider;
            _context = context;
        }
    
        public override async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            try
            {
                var order = await _context.Orders
                    .Include(o => o.ShippingDetails)
                    .Include(o => o.User)
                    .FirstOrDefaultAsync(o => o.Id == orderId);
                    
                if (order == null)
                    throw new KeyNotFoundException($"Order with ID {orderId} not found");

                // Only allow transitions to Confirmed or Cancelled
                if (request.NewStatus != "Potvrđeno" && request.NewStatus != "Otkazano")
                    throw new UserException($"Cannot change order from 'Procesiranje' to '{request.NewStatus}'");

                var oldState = order.OrderState;
                order.OrderState = request.NewStatus;

                await _context.SaveChangesAsync();

                // Send email notification about status change
                SendOrderStateChangeEmail(order, oldState);
                
                return await MapOrderToResponse(order);
            }
            catch (Exception ex)
            {
                throw new UserException($"Error changing order state: {ex.Message}", 500);
            }
        }

    }
}
