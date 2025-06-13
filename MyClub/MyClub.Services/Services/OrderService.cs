using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyClub.Services.Services
{
    public class OrderService : BaseService<OrderResponse, OrderSearchObject, Database.Order>, IOrderService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IUserService _userService;
        private readonly IPaymentService _paymentService;

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
            return response;
        }

        public async Task<OrderResponse> PlaceOrder(OrderInsertRequest request)
        {
            await Task.CompletedTask;
            return null;
        }

        public async Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request)
        {
            await Task.CompletedTask;
            return null;
        }
    }
} 