using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;

namespace MyClub.Services.Services
{
    public class StadiumSideService : BaseCRUDService<StadiumSideResponse, BaseSearchObject, StadiumSideUpsertRequest, StadiumSideUpsertRequest, StadiumSide>, IStadiumSideService
    {
        private readonly MyClubContext _context;
        
        public StadiumSideService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }
        
        public override async Task<bool> DeleteAsync(int id)
        {
            var isSideInUse = await _context.StadiumSectors.AnyAsync(s => s.StadiumSideId == id);

            if (isSideInUse)
            {
                throw new UserException($"Strana se ne može obrisati jer je trenutno korišćena od strane jednog ili više sektora.");
            }

            // Proceed with deletion if the stadium side is not in use
            return await base.DeleteAsync(id);
        }
    }
}
