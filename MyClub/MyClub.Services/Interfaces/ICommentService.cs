using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services.Interfaces
{
    public interface ICommentService : ICRUDService<CommentResponse, CommentSearchObject, CommentUpsertRequest, CommentUpsertRequest>
    {

    }
}