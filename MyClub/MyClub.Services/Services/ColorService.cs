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
        
        public ColorService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {

        }
    }
}
