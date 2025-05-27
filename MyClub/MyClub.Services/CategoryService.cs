using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest, Database.Category>, ICategoryService
    {
        private readonly MyClubContext _context;

        public CategoryService(MyClubContext context) : base(context)
        {
            _context = context;
        }

        protected override IQueryable<Database.Category> ApplyFilter(IQueryable<Database.Category> query, CategorySearchObject search)
        {  
            if(!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }
            if(!string.IsNullOrWhiteSpace(search?.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS) || x.Description.Contains(search.FTS));
            }

            return query;
        }

        public async Task<CategoryResponse> CreateAsync(CategoryUpsertRequest request)
        {
            var entity = await base.CreateAsync(request);
            return entity;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            return await base.DeleteAsync(id);
        }

        public async Task<CategoryResponse?> UpdateAsync(int id, CategoryUpsertRequest request)
        {
            return await base.UpdateAsync(id, request);
        }

        protected override CategoryResponse MapToResponse(Database.Category entity)
        {
            return new CategoryResponse
            {
                Id = entity.Id,
                Name = entity.Name,
                Description = entity.Description,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = null,
                ProductCount = entity.ProductCategories?.Count ?? 0
            };
        }

        protected override Database.Category MapInsertToEntity(Database.Category entity, CategoryUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.IsActive = true;
            entity.CreatedAt = DateTime.UtcNow;
            return entity;
        }

        protected override void MapUpdateToEntity(Database.Category entity, CategoryUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
        }
    }
} 