using System;
using System.Drawing;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IColorService : IService<ColorResponse, ColorSearchObject>
    {
        Task<ColorResponse> CreateAsync(ColorUpsertRequest request);
        Task<ColorResponse?> UpdateAsync(int id, ColorUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }


}
