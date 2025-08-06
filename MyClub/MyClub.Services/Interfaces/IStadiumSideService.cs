using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services.Interfaces
{
    public interface IStadiumSideService : ICRUDService<StadiumSideResponse, BaseSearchObject, StadiumSideUpsertRequest, StadiumSideUpsertRequest>
    {
    }
}
