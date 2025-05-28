using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface ICategoryService : ICRUDService<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
        Task<CategoryResponse> CreateAsync(CategoryUpsertRequest request);
        Task<CategoryResponse?> UpdateAsync(int id, CategoryUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
} 