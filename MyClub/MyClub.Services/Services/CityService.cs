using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services.Services
{
    public class CityService : BaseCRUDService<CityResponse, BaseSearchObject, CityUpsertRequest, CityUpsertRequest, City>, ICityService
    {
        private readonly MyClubContext _context;

        public CityService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        // Override GetAsync to include related data
        public override async Task<PagedResult<CityResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.Cities
                .AsNoTracking()
                .Include(c => c.Country)
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

            return new PagedResult<CityResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        // Override GetByIdAsync to include related data
        public override async Task<CityResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Cities
                .AsNoTracking()
                .Include(c => c.Country)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        // Override ApplyFilter to add custom filtering
        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, BaseSearchObject search)
        {
            // Implement full-text search
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(c =>
                    c.Name.ToLower().Contains(searchTerm) ||
                    c.PostalCode.ToLower().Contains(searchTerm) ||
                    c.Country.Name.ToLower().Contains(searchTerm)
                );
            }

           

            return query;
        }

        // Map entity to response
        protected override CityResponse MapToResponse(City entity)
        {
            var response = _mapper.Map<CityResponse>(entity);

            // Handle Country
            if (entity.Country != null)
            {
                response.Country = new CountryResponse
                {
                    Id = entity.Country.Id,
                    Name = entity.Country.Name,
                    Code = entity.Country.Code
                };
            }

            return response;
        }
        
        public override async Task<bool> DeleteAsync(int id)
        {
            var city = await _context.Cities
                .Include(c => c.Country)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (city == null)
            {
                throw new UserException("City not found");
            }

            // Check if the city is referenced in any shipping details
            bool hasReferencedShippingDetails = await _context.ShippingDetails
                .AnyAsync(sd => sd.CityId == city.Id);

            if (hasReferencedShippingDetails)
            {
                throw new UserException("Cannot delete city that is referenced in shipping details");
            }

            _context.Cities.Remove(city);
            return await _context.SaveChangesAsync() > 0;
        }
    }
}
