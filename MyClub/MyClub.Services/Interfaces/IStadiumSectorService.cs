using System;
using MyClub.Model.SearchObjects;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Model;
using MyClub.Model.Requests;

namespace MyClub.Services.Interfaces
{
    public interface IStadiumSectorService : ICRUDService<StadiumSectorResponse, BaseSearchObject, StadiumSectorUpsertRequest, StadiumSectorUpsertRequest>
    {
    }
}