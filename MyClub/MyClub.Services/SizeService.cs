using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;

namespace MyClub.Services
{
    public class SizeService : BaseCRUDService<SizeResponse, SizeSearchObject, SizeUpsertRequest, SizeUpsertRequest, Database.Size>, ISizeService
    {
        private readonly MyClubContext _context;

        public SizeService(MyClubContext context) : base(context)
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

        public async Task<SizeResponse> CreateAsync(SizeUpsertRequest request)
        {
            var entity = await base.CreateAsync(request);
            return entity;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            return await base.DeleteAsync(id);
        }

        public async Task<SizeResponse?> UpdateAsync(int id, SizeUpsertRequest request)
        {
            return await base.UpdateAsync(id, request);
        }

        protected override SizeResponse MapToResponse(Database.Size entity)
        {
            return new SizeResponse
            {
                Id = entity.Id,
                Name = entity.Name,
            };
        }

        protected override Database.Size MapInsertToEntity(Database.Size entity, SizeUpsertRequest request)
        {
            entity.Name = request.Name;
            return entity;
        }

        protected override void MapUpdateToEntity(Database.Size entity, SizeUpsertRequest request)
        {
            entity.Name = request.Name;
        }
    }
} 