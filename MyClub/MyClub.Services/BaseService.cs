using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{

    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : class where TEntity : class
    {
        private readonly MyClubContext _context;

        public BaseService(MyClubContext context)
        {
            _context = context;
        }

        public async Task<List<T>> GetAsync(TSearch search){
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);
            var list = await query.ToListAsync();
            return list.Select(MapToResponse).ToList(); 
        }
        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search){
            return query;
        }

        protected abstract T MapToResponse(TEntity entity);

        public async Task<T?> GetByIdAsync(int id){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                return null;
            }
            return MapToResponse(entity);
        }


    }
}
