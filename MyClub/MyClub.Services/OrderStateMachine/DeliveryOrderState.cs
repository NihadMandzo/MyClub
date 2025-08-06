using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MyClub.Model.Requests;
using MyClub.Model.Responses;

namespace MyClub.Services.OrderStateMachine
{
    public class DeliveryOrderState : BaseOrderState
    {
        private readonly ILogger<DeliveryOrderState> _logger;
        
        public DeliveryOrderState(IServiceProvider serviceProvider) 
            : base(serviceProvider)
        {
            _logger = serviceProvider.GetRequiredService<ILogger<DeliveryOrderState>>();
        }
        
        public override async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            try
            {
                var order = await _context.Orders
                    .Include(o => o.ShippingDetails)
                    .FirstOrDefaultAsync(o => o.Id == orderId);
                    
                if (order == null)
                    throw new KeyNotFoundException($"Order with ID {orderId} not found");
                    
                // Only allow transition to Finished
                if (request.NewStatus != "Završeno")
                    throw new UserException($"Cannot change order from 'Dostava' to '{request.NewStatus}'");
                
                order.OrderState = request.NewStatus;
                order.DeliveredDate = DateTime.Now;
                
                await _context.SaveChangesAsync();
                
                // Optional: Send email notification about completed delivery
                // await SendDeliveryCompletedNotification(order);
                
                return await MapOrderToResponse(order);
            }
            catch (Exception ex)
            {
                throw new UserException($"Error changing order state: {ex.Message}", 400);
            }
        }
    }
}
