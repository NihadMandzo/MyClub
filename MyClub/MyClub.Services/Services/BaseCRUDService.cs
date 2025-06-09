using System;
using System.Threading.Tasks;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;

namespace MyClub.Services
{
    public abstract class BaseCRUDService<T, TSearch, TInsert, TUpdate, TEntity> : BaseService<T, TSearch, TEntity>, ICRUDService<T, TSearch, TInsert, TUpdate>
    where T : class where TSearch : BaseSearchObject where TEntity : class, new() where TInsert : class where TUpdate : class
    {
        private readonly MyClubContext _context;

        public BaseCRUDService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        public virtual async Task<T> CreateAsync(TInsert request)  {
            var entity = MapInsertToEntity(new TEntity(), request);
            await BeforeInsert(entity, request);
            _context.Set<TEntity>().Add(entity);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeInsert(TEntity entity, TInsert request){
            await Task.CompletedTask;
        }
        protected virtual TEntity MapInsertToEntity(TEntity entity, TInsert request){
            return _mapper.Map<TEntity>(request);
        }
        public virtual async Task<T> UpdateAsync(int id, TUpdate request){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                throw new Exception("Entity not found");
            }
            entity = MapUpdateToEntity(entity, request);
            await BeforeUpdate(entity, request);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }
        protected virtual async Task BeforeUpdate(TEntity entity, TUpdate request){
            await Task.CompletedTask;
        }
        protected virtual TEntity MapUpdateToEntity(TEntity entity, TUpdate request){
            return _mapper.Map(request, entity);
        }
        public virtual async Task<bool> DeleteAsync(int id){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                throw new Exception("Entity not found");
            }
            await BeforeDelete(entity);
            _context.Set<TEntity>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
        protected virtual async Task BeforeDelete(TEntity entity)
        {
            await Task.CompletedTask;
        }
    }
}