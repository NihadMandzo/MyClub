using System;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model;

namespace MyClub.Services.Services
{
    public class StadiumSectorService : BaseService<StadiumSectorResponse, BaseSearchObject, StadiumSector>, IStadiumSectorService
    {
        public StadiumSectorService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
        }
    }
}