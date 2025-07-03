using System;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services.Services
{
    public class StadiumSectorService : BaseService<StadiumSector, BaseSearchObject, StadiumSector>, IStadiumSectorService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;
        public StadiumSectorService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<StadiumSector[]> GetAllStadiumSectorsAsync()
        {
            return await _context.StadiumSectors.ToArrayAsync();
        }

        public async Task<StadiumSector> GetStadiumSectorByIdAsync(int id)
        {
            return await _context.StadiumSectors.FindAsync(id);
        }

        public async Task<PagedResult<StadiumSector>> GetStadiumSectorsAsync(BaseSearchObject search)
        {
            var query = _context.StadiumSectors
                .Include(s => s.StadiumSide)
                .AsQueryable();
                
            // Apply filters
            query = ApplyFilter(query, search);
            
            // Get total count before pagination
            int totalCount = 0;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }
            
            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;
            
            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }
            
            var list = await query.ToListAsync();
            
            return new PagedResult<StadiumSector>
            {
                Data = list,
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

    }
}