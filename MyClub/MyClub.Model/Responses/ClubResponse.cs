using System;

namespace MyClub.Model.Responses
{

    public class ClubResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ImageUrl { get; set; }
        public DateTime EstablishedDate { get; set; }
        public string StadiumName { get; set; }
        public string StadiumLocation { get; set; }
        public int NumberOfTitles { get; set; }

    }
}