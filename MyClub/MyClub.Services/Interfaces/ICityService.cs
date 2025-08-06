using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services.Interfaces
{
    public interface ICityService : ICRUDService<CityResponse, BaseSearchObject, CityUpsertRequest, CityUpsertRequest>
    {
    }
}
