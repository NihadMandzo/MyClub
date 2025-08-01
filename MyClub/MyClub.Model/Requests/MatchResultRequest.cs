using System;
using Microsoft.AspNetCore.Http;

namespace MyClub.Model.Requests
{
    public class MatchResultRequest
    {
        public int HomeGoals { get; set; }
        public int AwayGoals { get; set; }
    }
}