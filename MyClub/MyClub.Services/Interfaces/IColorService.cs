using System;
using System.Drawing;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IColorService : ICRUDService<ColorResponse, ColorSearchObject, ColorUpsertRequest, ColorUpsertRequest>
    {
    }


}
