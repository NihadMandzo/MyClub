using System;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;   
using MyClub.Services.Interfaces;
using MyClub.Services.Database;
using Microsoft.EntityFrameworkCore;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using MyClub.Services.Helpers;

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
            var entity = MapInsertToEntity(new Database.Comment(), request);
            await BeforeInsert(entity, request);
            _context.Comments.Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<CommentResponse>(entity);
        }
        public override async Task<CommentResponse> UpdateAsync(int id, CommentUpsertRequest request)
        {
            var entity = await _context.Comments.FindAsync(id);
            var updatedEntity = MapUpdateToEntity(entity, request);
            await BeforeUpdate(updatedEntity, request);
            _context.Comments.Update(updatedEntity);
            await _context.SaveChangesAsync();
            return MapToResponse(updatedEntity);
        }
        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Comments.FindAsync(id);
            if (entity == null)
            {
                return false; // Entity not found
            }
            await BeforeDelete(entity);
            _context.Comments.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
        protected override async Task BeforeDelete(Database.Comment entity)
        {
            string authHeader = _httpContextAccessor.HttpContext.Request.Headers["Authorization"];
            var userId = JwtTokenManager.GetUserIdFromToken(authHeader);
            if (entity.UserId != userId && !JwtTokenManager.IsAdmin(authHeader))
            {
                throw new UnauthorizedAccessException("You are not authorized to delete this comment.");
            }
            await Task.CompletedTask;
        }
        protected override CommentResponse MapToResponse(Database.Comment entity)
        {
            var comment = _mapper.Map<CommentResponse>(entity);
            comment.Username = JwtTokenManager.GetUsernameFromToken(_httpContextAccessor.HttpContext.Request.Headers["Authorization"]);
            return comment;
        }
        protected override Database.Comment MapInsertToEntity(Database.Comment entity, CommentUpsertRequest request)
        {
            entity.Content = request.Content;
            entity.CreatedAt = DateTime.Now;
            return entity;
        }
        protected override Database.Comment MapUpdateToEntity(Database.Comment entity, CommentUpsertRequest request)
        {
            return entity;
        }
        protected override async Task BeforeInsert(Database.Comment entity, CommentUpsertRequest request)
        {
            string authHeader = _httpContextAccessor.HttpContext.Request.Headers["Authorization"];
            entity.UserId = JwtTokenManager.GetUserIdFromToken(authHeader);
            entity.NewsId = request.NewsId;
            await Task.CompletedTask;
        }
        protected override async Task BeforeUpdate(Database.Comment entity, CommentUpsertRequest request)
        {
            string authHeader = _httpContextAccessor.HttpContext.Request.Headers["Authorization"];
            var userId = JwtTokenManager.GetUserIdFromToken(authHeader);
            if (entity.UserId != userId)
            {
                throw new UnauthorizedAccessException("You are not authorized to update this comment.");
            }
            await Task.CompletedTask;
        }
        protected override IQueryable<Database.Comment> ApplyFilter(IQueryable<Database.Comment> query, CommentSearchObject? search){
            if (search?.NewsId != null) query = query.Where(x => x.NewsId == search.NewsId);
            return query;
        }
        public override async Task<PagedResult<CommentResponse>> GetAsync(CommentSearchObject? search = null)
        {
            var query = _context.Comments.AsQueryable();
            
            query = ApplyFilter(query, search);

            var totalCount = await query.CountAsync();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();

            var result = new PagedResult<CommentResponse>
            {
                Data = list.Select(x => MapToResponse(x)).ToList(),
                TotalCount = totalCount
            };

            return result;
        }
    }
}