using System;

namespace MyClub.Model.Responses
{

    public class ClubResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ImageUrl { get; set; }

    }
}