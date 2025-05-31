using System;
using MyClub.Model.SearchObjects;
using MyClub.Model.Responses;
using MyClub.Services.Database;

namespace MyClub.Services.Interfaces
{
    public interface IStadiumSectorService : IService<StadiumSector, BaseSearchObject>
    {
        Task<StadiumSector[]> GetAllStadiumSectorsAsync();
        Task<StadiumSector> GetStadiumSectorByIdAsync(int id);

    }
}