using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;
namespace MyClub.Services
{
    public class SizeService : BaseCRUDService<SizeResponse, SizeSearchObject, SizeUpsertRequest, SizeUpsertRequest, Database.Size>, ISizeService
    {
        private readonly MyClubContext _context;

        public SizeService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<Database.Size> ApplyFilter(IQueryable<Database.Size> query, SizeSearchObject search)
        {  
            if(!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }
            if(!string.IsNullOrWhiteSpace(search?.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS));
            }
            return query;
        }

    }
} 