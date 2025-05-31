using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;   
using MyClub.Services.Interfaces;
using MyClub.Services.Database;

using MapsterMapper;
using Microsoft.AspNetCore.Http;
using MyClub.Services.Utilities;

namespace MyClub.Services.Services
{

    public class CommentService : BaseCRUDService<CommentResponse, CommentSearchObject, CommentUpsertRequest, CommentUpsertRequest, Database.Comment>, ICommentService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CommentService(MyClubContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
        }

        public override async Task<CommentResponse> CreateAsync(CommentUpsertRequest request)
        {
            var entity = _mapper.Map<Database.Comment>(request);
            await BeforeInsert(entity, request);
            await _context.SaveChangesAsync();
            return _mapper.Map<CommentResponse>(entity);
        }

        public override async Task<CommentResponse> UpdateAsync(int id, CommentUpsertRequest request)
        {
            var entity = await _context.Comments.FindAsync(id);
            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<CommentResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Comments.FindAsync(id);
            _context.Comments.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }


        protected override CommentResponse MapToResponse(Database.Comment entity)
        {
            return _mapper.Map<CommentResponse>(entity);
        }

        protected override Database.Comment MapInsertToEntity(Database.Comment entity, CommentUpsertRequest request)
        {
            string authHeader = _httpContextAccessor.HttpContext.Request.Headers["Authorization"];
            entity.UserId = JwtTokenManager.GetUserIdFromToken(authHeader);
            entity.CreatedAt = DateTime.Now;
            return entity;
        }

        
    }
}