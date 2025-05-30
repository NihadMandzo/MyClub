using System;

namespace MyClub.Model.Responses
{
    public class UserException : Exception
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }

        public UserException(string message, int statusCode = 400) : base(message)
        {
            StatusCode = statusCode;
            Message = message;
        }
    }
}