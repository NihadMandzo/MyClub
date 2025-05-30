using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services.Interfaces
{

    public interface INewsService : ICRUDService<NewsResponse, NewsSearchObject, NewsUpsertRequest, NewsUpsertRequest>
    {
        Task<NewsResponse> CreateAsync(NewsUpsertRequest request);
        Task<NewsResponse?> UpdateAsync(int id, NewsUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
