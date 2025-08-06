using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface ICategoryService : ICRUDService<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
    }
} 