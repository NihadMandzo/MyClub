using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyClub.Services.Interfaces
{
    public interface IOrderService : IService<OrderResponse, OrderSearchObject>
    {
        Task<PagedResult<OrderResponse>> GetUserOrdersAsync(int userId);
        Task<PaymentResponse> PlaceOrder(OrderInsertRequest request);
        Task<OrderResponse> ConfirmOrder(ConfirmOrderRequest request);
        Task<OrderResponse> ChangeOrderState(int orderId, OrderStateUpdateRequest request);
    }
} 