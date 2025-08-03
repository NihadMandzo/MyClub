using System;
using System.Collections.Generic;

namespace MyClub.Model.Responses
{
    public enum OrderStatus
    {
        Pending,
        Processing,
        Shipped,
        Delivered,
        Cancelled,
        Refunded
    }

    public class OrderResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; }
        public int? PaymentId { get; set; }
        public DateTime OrderDate { get; set; }
        public string OrderState { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal OriginalAmount { get; set; }
        public decimal DiscountAmount { get; set; }
        public bool HasMembershipDiscount { get; set; }
        public string ShippingAddress { get; set; }
        public string ShippingCity { get; set; }
        public string ShippingPostalCode { get; set; }
        public string ShippingCountry { get; set; }
        public string PaymentMethod { get; set; }
        public DateTime? ShippedDate { get; set; }
        public DateTime? DeliveredDate { get; set; }
        public string Notes { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; }
    }
} 