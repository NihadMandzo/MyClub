using System;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model;

namespace MyClub.Services.Services
{
    public class StadiumSectorService : BaseService<StadiumSectorResponse, BaseSearchObject, StadiumSector>, IStadiumSectorService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;

        public StadiumSectorService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<StadiumSectorResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.StadiumSectors
                .Include(s => s.StadiumSide) // Assuming StadiumSide is a navigation property in StadiumSector
                .FirstOrDefaultAsync(s => s.Id == id);
             if (entity == null) return null;

            return MapToResponse(entity);
        }

        public override async Task<PagedResult<StadiumSectorResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.StadiumSectors.Include(s => s.StadiumSide).AsQueryable();

            int totalCount = 0;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;

            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();

            return new PagedResult<StadiumSectorResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        protected override StadiumSectorResponse MapToResponse(StadiumSector entity)
        {
            var result = _mapper.Map<StadiumSectorResponse>(entity);
            result.SideName = entity.StadiumSide.Name; // Assuming StadiumSide is a navigation property in StadiumSector
            return result;
        }
    }
}