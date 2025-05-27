using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public class ColorService : BaseCRUDService<ColorResponse, ColorSearchObject, ColorUpsertRequest, ColorUpsertRequest, Database.Color>, IColorService
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


        public async Task<ColorResponse> CreateAsync(ColorUpsertRequest request)
        {
            var entity = await base.CreateAsync(request);
            return entity;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            return await base.DeleteAsync(id);
        }

        public async Task<ColorResponse?> UpdateAsync(int id, ColorUpsertRequest request)
        {
            return await base.UpdateAsync(id, request);
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
        protected override Database.Color MapInsertToEntity(Database.Color entity, ColorUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.HexCode = request.HexCode;
            return entity;
        }
        protected override void MapUpdateToEntity(Database.Color entity, ColorUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.HexCode = request.HexCode;
        }
    }
}
