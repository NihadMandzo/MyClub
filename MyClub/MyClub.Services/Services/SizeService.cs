using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;
namespace MyClub.Services
{
    public class SizeService : BaseCRUDService<SizeResponse, SizeSearchObject, SizeUpsertRequest, SizeUpsertRequest, Database.Size>, ISizeService
    {
        private readonly MyClubContext _context;

        public SizeService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        
        
        public override async Task<bool> DeleteAsync(int id)
        {
            var isSizeInUse = await _context.Products.Include(p => p.ProductSizes).AnyAsync(p => p.ProductSizes.Any(ps => ps.SizeId == id));

            if (isSizeInUse)
            {
                throw new UserException($"Veličina se ne može obrisati jer je trenutno korišćena od strane jednog ili više proizvoda.");
            }

            // Proceed with deletion if the size is not in use
            return await base.DeleteAsync(id);
        }

    }
} 