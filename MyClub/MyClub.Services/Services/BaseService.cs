using System;
using System.Linq;
using System.Threading.Tasks;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services
{

    public abstract class  BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TEntity : class
    {
        private readonly MyClubContext _context;
        protected readonly IMapper _mapper;

        public BaseService(MyClubContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search){
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);
            
            int totalCount = 0;
            // Get total count if requested
            if(search.IncludeTotalCount){
                totalCount = await query.CountAsync();
            }
            
            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;
            
            if(!search.RetrieveAll){
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }
            
            var list = await query.ToListAsync();
            
            return new PagedResult<T>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }
        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search){
            return query;
        }
        protected virtual T MapToResponse(TEntity entity){
            return _mapper.Map<T>(entity);
        }
        public virtual async Task<T?> GetByIdAsync(int id){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                return null;
            }
            return MapToResponse(entity);
        }
    }
}
