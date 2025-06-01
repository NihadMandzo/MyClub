using System;
using MapsterMapper;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services.Services
{
    public class PlayerService : BaseCRUDService<PlayerResponse, PlayerSearchObject, PlayerInsertRequest, PlayerUpdateRequest, Player>, IPlayerInterface
    {
        public PlayerService(MyClubContext context, IMapper mapper) : base(context, mapper)
        {
        }
    }
}