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

        public CategoryService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
        }

    }
} 