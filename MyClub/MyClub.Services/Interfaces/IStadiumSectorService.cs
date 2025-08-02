using System;
using MyClub.Model.SearchObjects;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Model;

namespace MyClub.Services.Interfaces
{
    public interface IStadiumSectorService : IService<StadiumSectorResponse, BaseSearchObject>
    {
    }
}