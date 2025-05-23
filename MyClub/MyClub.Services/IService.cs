using System;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IService<T, TSearch> where T : class where TSearch : class
    {
        Task<List<T>> GetAsync(TSearch search);
        Task<T?> GetByIdAsync(int id);
    }
}
