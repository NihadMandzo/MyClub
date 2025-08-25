using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MyClub.Model.Requests;
using MyClub.Model.Responses;

namespace MyClub.Services.OrderStateMachine
{
    public class CancelledOrderState : BaseOrderState
    {
        private readonly ILogger<CancelledOrderState> _logger;
        
        public CancelledOrderState(IServiceProvider serviceProvider) 
            : base(serviceProvider)
        {
            _logger = serviceProvider.GetRequiredService<ILogger<CancelledOrderState>>();
        }
        
        public override async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            // Cannot change state from cancelled
            throw new UserException("Ne možete promeniti fazu iz 'Otkazano'");
        }
    }
}
