using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;

namespace MyClub.Services
{
    public class ColorService : BaseCRUDService<ColorResponse, ColorSearchObject, ColorUpsertRequest, ColorUpsertRequest, Database.Color>, IColorService
    {
        private readonly MyClubContext _context;

        public ColorService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }
        protected override IQueryable<Database.Color> ApplyFilter(IQueryable<Database.Color> query, ColorSearchObject search){  
            if(!string.IsNullOrWhiteSpace(search?.Name)){
                query = query.Where(x => x.Name.Contains(search.Name));
            }
            if(!string.IsNullOrWhiteSpace(search?.FTS)){
                query = query.Where(x => x.Name.Contains(search.FTS) || x.HexCode.Contains(search.FTS));
            }
            return query;
        }

    }
}
