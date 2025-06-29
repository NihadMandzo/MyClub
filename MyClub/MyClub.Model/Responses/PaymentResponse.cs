using System;

namespace MyClub.Model.Responses
{
    public class PaymentResponse
    {
        public string clientSecret {get; set;}
        public string transactionId {get; set;}
    }
}