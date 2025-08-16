using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyClub.Services.Services
{
    public class CountryService : BaseCRUDService<CountryResponse, BaseSearchObject, CountryUpsertRequest, CountryUpsertRequest, Country>, ICountryService
    {
        private readonly MyClubContext _context;

        public CountryService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        // Override GetAsync to include related data
        public override async Task<PagedResult<CountryResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.Countries
                .AsNoTracking()
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
            
            return new PagedResult<CountryResponse>
            {
                Data = list.Select(base.MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        // Override GetByIdAsync to include related data
        public override async Task<CountryResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Countries
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            return base.MapToResponse(entity);
        }

        // Override ApplyFilter to add custom filtering
        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, BaseSearchObject search)
        {
            // Implement full-text search
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(c => 
                    c.Name.ToLower().Contains(searchTerm) || 
                    c.Code.ToLower().Contains(searchTerm)
                );
            }


            return query;
        }

        // Override DeleteAsync to handle cascading deletes
        public override async Task<bool> DeleteAsync(int id)
        {
            var country = await _context.Countries
                .Include(c => c.Cities)
                .ThenInclude(c => c.ShippingDetails)
                .Include(c => c.Players)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (country == null)
            {
                throw new UserException("Country not found");
            }

            // Check if any cities are referenced in orders
            bool hasReferencedCities = false;
            foreach (var city in country.Cities)
            {
                if (city.ShippingDetails.Any(sd => sd.Orders.Any()))
                {
                    hasReferencedCities = true;
                    break;
                }
            }

            if (hasReferencedCities)
            {
                throw new UserException("Cannot delete the country because some of its cities are referenced in orders");
            }

            bool hasPlayers = await _context.Players.AnyAsync(p => p.CountryId == id);
            if (hasPlayers)
            {
                throw new UserException("Cannot delete the country because it has players associated with it");
            }


            // Remove cities that aren't referenced in orders
            foreach (var city in country.Cities.ToList())
            {
                _context.Cities.Remove(city);
            }

            // Remove the country
            _context.Countries.Remove(country);
            await _context.SaveChangesAsync();
            
            return true;
        }

    }
}
