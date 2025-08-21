using System;
using System.Linq;
using System.Threading.Tasks;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model;

namespace MyClub.Services.Services
{
    public class StadiumSectorService : BaseCRUDService<StadiumSectorResponse, BaseSearchObject, StadiumSectorUpsertRequest, StadiumSectorUpsertRequest, StadiumSector>, IStadiumSectorService
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
                .Include(s => s.StadiumSide)
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
            if (entity.StadiumSide != null)
            {
                result.StadiumSide = new StadiumSideResponse
                {
                    Id = entity.StadiumSide.Id,
                    Name = entity.StadiumSide.Name
                };
            }
            return result;
        }

        protected override async Task BeforeInsert(StadiumSector entity, StadiumSectorUpsertRequest request)
        {
            // Validate that the StadiumSide exists
            var stadiumSideExists = await _context.StadiumSides.AnyAsync(s => s.Id == request.StadiumSideId);
            if (!stadiumSideExists)
            {
                throw new UserException($"Stadium side with ID {request.StadiumSideId} does not exist.");
            }
            
            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(StadiumSector entity, StadiumSectorUpsertRequest request)
        {
            // Validate that the StadiumSide exists
            var stadiumSideExists = await _context.StadiumSides.AnyAsync(s => s.Id == request.StadiumSideId);
            if (!stadiumSideExists)
            {
                throw new UserException($"Stadium side with ID {request.StadiumSideId} does not exist.");
            }
            
            await Task.CompletedTask;
        }
    }
}