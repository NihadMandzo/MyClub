using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services.Interfaces
{
    public interface IClubService : ICRUDService<ClubResponse,BaseSearchObject, ClubRequest, ClubRequest>
    {

    }
}