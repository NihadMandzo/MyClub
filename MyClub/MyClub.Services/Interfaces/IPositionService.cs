using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IPositionService : ICRUDService<PositionResponse, BaseSearchObject, PositionUpsertRequest, PositionUpsertRequest>
    {
    }
} 