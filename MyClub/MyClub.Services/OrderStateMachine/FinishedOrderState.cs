using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MyClub.Model.Requests;
using MyClub.Model.Responses;

namespace MyClub.Services.OrderStateMachine
{
    public class FinishedOrderState : BaseOrderState
    {
        private readonly ILogger<FinishedOrderState> _logger;
        
        public FinishedOrderState(IServiceProvider serviceProvider) 
            : base(serviceProvider)
        {
            _logger = serviceProvider.GetRequiredService<ILogger<FinishedOrderState>>();
        }
        
        public override async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            // Cannot change state from finished
            throw new UserException("Cannot change state from 'Zavrseno'");
        }
    }
}
