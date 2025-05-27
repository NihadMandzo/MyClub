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
    }
} 