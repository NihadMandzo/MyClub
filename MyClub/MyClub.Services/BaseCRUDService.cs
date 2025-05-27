using System;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public abstract class BaseCRUDService<T, TSearch, TInsert, TUpdate, TEntity> : BaseService<T, TSearch, TEntity>
    where T : class where TSearch : BaseSearchObject where TEntity : class, new() where TInsert : class where TUpdate : class
    {
        private readonly MyClubContext _context;

        public BaseCRUDService(MyClubContext context) : base(context)
        {
            _context = context;
        }

        public virtual async Task<T> CreateAsync(TInsert request)  {
            var entity = new TEntity();
            MapInsertToEntity(entity, request);
            await BeforeInsert(entity, request);
            _context.Set<TEntity>().Add(entity);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeInsert(TEntity entity, TInsert request){
            await Task.CompletedTask;
        }
        protected abstract TEntity MapInsertToEntity(TEntity entity, TInsert request);

        protected override T MapToResponse(TEntity entity){
            throw new NotImplementedException();
        }

        public virtual async Task<T> UpdateAsync(int id, TUpdate request){
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if(entity == null){
                throw new Exception("Entity not found");
            }
            MapUpdateToEntity(entity, request);
            await BeforeUpdate(entity, request);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeUpdate(TEntity entity, TUpdate request){
            await Task.CompletedTask;
        }
        protected abstract void MapUpdateToEntity(TEntity entity, TUpdate request);
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