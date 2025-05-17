using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IProductTypeService
    {
        Task<List<ProductTypeResponse>> Get(ProductTypeSearchObject search);
        Task<List<ProductTypeResponse>> GetAllAsync();
        Task<ProductTypeResponse?> GetByIdAsync(int id);
        Task<ProductTypeResponse> CreateAsync(ProductTypeUpsertRequest request);
        Task<ProductTypeResponse?> UpdateAsync(int id, ProductTypeUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
} 