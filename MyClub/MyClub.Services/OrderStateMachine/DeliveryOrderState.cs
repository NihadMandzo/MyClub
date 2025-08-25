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
                    .Include(o => o.User)
                    .FirstOrDefaultAsync(o => o.Id == orderId);
                    
                if (order == null)
                    throw new KeyNotFoundException($"Narudžba sa ID {orderId} nije pronađena");

                // Only allow transition to Finished
                if (request.NewStatus != "Završeno")
                    throw new UserException($"Ne možete promeniti fazu narudžbe iz 'Dostava' u '{request.NewStatus}'");
                var oldState = order.OrderState;
                order.OrderState = request.NewStatus;
                order.DeliveredDate = DateTime.Now;
                
                await _context.SaveChangesAsync();
                
                // Optional: Send email notification about completed delivery
                // await SendDeliveryCompletedNotification(order);
                base.SendOrderStateChangeEmail(order, oldState);
                return await MapOrderToResponse(order);
            }
            catch (Exception ex)
            {
                throw new UserException($"Greška prilikom promene faze narudžbe: {ex.Message}", 400);
            }
        }
    }
}
