using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;

namespace MyClub.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest, Database.Category>, ICategoryService
    {
        private readonly MyClubContext _context;
        public CategoryService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var isCategoryInUse = await _context.Products.AnyAsync(p => p.CategoryId == id);

            if (isCategoryInUse)
            {
                throw new UserException($"Cannot delete this category as it's currently used by one or more products.");
            }

            // Proceed with deletion if the category is not in use
            return await base.DeleteAsync(id);
        }
    }
}