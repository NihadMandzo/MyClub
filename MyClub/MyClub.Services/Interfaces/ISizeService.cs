using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface ISizeService : ICRUDService<SizeResponse, SizeSearchObject, SizeUpsertRequest, SizeUpsertRequest>
    {
        Task<SizeResponse> CreateAsync(SizeUpsertRequest request);
        Task<SizeResponse?> UpdateAsync(int id, SizeUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
} 