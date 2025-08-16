using System;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;

namespace MyClub.Services
{
    public class PositionService : BaseCRUDService<PositionResponse, BaseSearchObject, PositionUpsertRequest, PositionUpsertRequest, Database.Position>, IPositionService
    {
        private readonly MyClubContext _context;
        public PositionService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var isPositionInUse = await _context.Players.AnyAsync(p => p.PositionId == id);

            if (isPositionInUse)
            {
                throw new UserException($"Cannot delete this position as it's currently used by one or more players.");
            }

            // Proceed with deletion if the category is not in use
            return await base.DeleteAsync(id);
        }
    }
}