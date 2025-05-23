using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public class ColorService : BaseService<ColorResponse, ColorSearchObject, Database.Color>, IColorService
    {
        private readonly MyClubContext _context;

        public ColorService(MyClubContext context) : base(context)
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


        public Task<ColorResponse> CreateAsync(ColorUpsertRequest request)
        {
            throw new NotImplementedException();
        }

        public Task<bool> DeleteAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<ColorResponse?> UpdateAsync(int id, ColorUpsertRequest request)
        {
            throw new NotImplementedException();
        }

        protected override ColorResponse MapToResponse(Database.Color entity)
        {
            return new ColorResponse
            {
                Id = entity.Id,
                Name = entity.Name,
                HexCode = entity.HexCode
            };
        }
    }
}
