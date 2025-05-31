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
            var query = _context.StadiumSectors.AsQueryable();
            query = ApplyFilter(query, search);
            return await GetAsync(search);
        }

    }
}