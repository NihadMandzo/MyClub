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
        
        public override async Task<bool> DeleteAsync(int id)
        {
            var isColorInUse = await _context.Products.AnyAsync(p => p.ColorId == id);

            if (isColorInUse)
            {
                throw new UserException($"Cannot delete this color as it's currently used by one or more products.");
            }

            // Proceed with deletion if the color is not in use
            return await base.DeleteAsync(id);
        }
    }
}
