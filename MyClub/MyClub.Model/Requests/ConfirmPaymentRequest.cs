using System;

namespace MyClub.Model.Requests
{
    public class ConfirmOrderRequest : OrderInsertRequest
    {
        public Guid TransactionId { get; set; }
    }
}