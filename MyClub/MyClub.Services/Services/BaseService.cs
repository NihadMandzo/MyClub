using System;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{

    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TEntity : class
    {
        private readonly MyClubContext _context;
        protected readonly IMapper _mapper;

        public BaseService(MyClubContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PagedResult<T>> GetAsync(TSearch search){
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);
            if(search.IncludeTotalCount){
                var totalCount = await query.CountAsync();
            }
            if(!search.RetrieveAll){
                if(search.Page.HasValue)
                {
                    query = query.Skip((search.Page.Value) * search.PageSize.Value);
                }
                if(search.PageSize.HasValue){
                    query = query.Take(search.PageSize.Value);
                }
            }
            var list = await query.ToListAsync();
            return new PagedResult<T>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = await query.CountAsync()
            };
        }
        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search){
            return query;
        }

        protected virtual T MapToResponse(TEntity entity){
            return _mapper.Map<T>(entity);
        }

        public async Task<T?> GetByIdAsync(int id){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                return null;
            }
            return MapToResponse(entity);
        }


    }
}
