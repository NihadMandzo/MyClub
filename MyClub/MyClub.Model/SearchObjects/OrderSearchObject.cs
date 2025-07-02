using System;
using MyClub.Model.Responses;

namespace MyClub.Model.SearchObjects
{
    public class OrderSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public OrderStatus? Status { get; set; }
    }
} 