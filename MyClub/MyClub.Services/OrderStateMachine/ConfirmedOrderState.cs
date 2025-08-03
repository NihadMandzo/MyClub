using System;
using System.Threading.Tasks;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;
using MyClub.Model.Responses;
using MyClub.Model.Requests;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using MyClub.Services.Helpers;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using MyClub.Services.OrderStateMachine;

namespace MyClub.Services.OrderStateMachine
{
    public class ConfirmedOrderState : BaseOrderState
    {

        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IPaymentService _paymentService;
        private readonly MyClubContext _context;
        
        private readonly IServiceProvider _serviceProvider;
        public ConfirmedOrderState(IServiceProvider serviceProvider,
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
            var entity = await _context.Orders
                .Include(o => o.ShippingDetails)
                .FirstOrDefaultAsync(o => o.Id == orderId);
                
            if (entity == null)
            {
                throw new KeyNotFoundException($"Order with ID {orderId} not found");
            }
            // Disallow changing state to Processing 
            if (request.NewStatus == "Procesiranje")
            {
                throw new UserException($"Cannot change order from 'Potvrđeno' to '{request.NewStatus}'");
            }
            if(request.NewStatus == "Dostava")
            {
                // If changing to Delivery, set delivery date
                entity.ShippedDate = DateTime.Now;
            }


            entity.OrderState = request.NewStatus;
            await _context.SaveChangesAsync();
            return await MapOrderToResponse(entity);
        }

    }
}