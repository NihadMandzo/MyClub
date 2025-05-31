using System;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Model.Requests;
using MyClub.Services.Interfaces;
using MyClub.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Services.Helpers;
using Microsoft.AspNetCore.Http;

namespace MyClub.Services.Services
{
    public class NewsService : BaseCRUDService<NewsResponse, NewsSearchObject, NewsUpsertRequest, NewsUpsertRequest, Database.News>, INewsService
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private const string _containerName = "news";
        private readonly IHttpContextAccessor _httpContextAccessor;
        
        public NewsService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
            _httpContextAccessor = httpContextAccessor;
        }
        //GET ALL NEWS
        public override async Task<PagedResult<NewsResponse>> GetAsync(NewsSearchObject search)
        {
            var query = _context.News.Include(n=>n.NewsAssets).ThenInclude(n=>n.Asset).Include(n=>n.Comments).OrderByDescending(x=>x.CreatedAt).AsQueryable();
            query = ApplyFilter(query, search);

            if (search.IncludeTotalCount)
            {
                var totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip((search.Page.Value) * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();
            return new PagedResult<NewsResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = await query.CountAsync()
            };
        }

        //APPLY FILTER
        protected override IQueryable<Database.News> ApplyFilter(IQueryable<Database.News> query, NewsSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Title))
            {
                query = query.Where(n => n.Title.Contains(search.Title));
            }
            if (!string.IsNullOrWhiteSpace(search?.Content))
            {
                query = query.Where(n => n.Content.Contains(search.Content));
            }
            if(!string.IsNullOrWhiteSpace(search?.FTS)){
                query = query.Where(n=> n.Content.Contains(search.FTS) || n.Content.Contains(search.FTS));
            }
            return query;
        }

        //GET NEWS BY ID
        public override async Task<NewsResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.News.Include(n=>n.NewsAssets).ThenInclude(x=>x.Asset).Include(n=>n.Comments).FirstOrDefaultAsync(n=>n.Id == id);
            if(entity == null){
                return null;
            }
            return MapToResponse(entity);
        }
        
        //CREATE NEWS
        public override async Task<NewsResponse> CreateAsync(NewsUpsertRequest request)
        {
            var entity = MapInsertToEntity(new Database.News(), request);
            await BeforeInsert(entity, request);
            _context.News.Add(entity);
            await _context.SaveChangesAsync();

            if(request.Images != null && request.Images.Any()){
                foreach(var image in request.Images){
                    var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                    var asset = new Asset(){
                        Url = imageUrl
                    };
                    await _context.Assets.AddAsync(asset);
                    await _context.SaveChangesAsync();

                    var newsAsset = new NewsAsset(){
                        NewsId = entity.Id,
                        AssetId = asset.Id
                    };
                    await _context.NewsAssets.AddAsync(newsAsset);
                    await _context.SaveChangesAsync();
                }
            }
            return MapToResponse(entity);
        }

        //BEFORE INSERT
        protected override Task BeforeInsert(News entity, NewsUpsertRequest request)
        {
            string authHeader = _httpContextAccessor.HttpContext.Request.Headers["Authorization"];
        
            entity.UserId = JwtTokenManager.GetUserIdFromToken(authHeader);
            entity.CreatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }

        //UPDATE NEWS
        public override async Task<NewsResponse> UpdateAsync(int id, NewsUpsertRequest request)
        {
            var entity = await _context.News
                .Include(n => n.NewsAssets)
                .ThenInclude(na => na.Asset)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null)
            {
                throw new UserException("News not found");
            }

            var updatedEntity = MapUpdateToEntity(entity, request);
            await BeforeUpdate(updatedEntity, request);

            // Handle images
            // Delete all existing images since we're not tracking which ones to keep
            var imagesToDelete = updatedEntity.NewsAssets.ToList();
            foreach (var image in imagesToDelete)
            {
                // Delete from Azure Blob Storage
                await _blobStorageService.DeleteAsync(image.Asset.Url, _containerName);

                // Remove from database
                _context.NewsAssets.Remove(image);
                _context.Assets.Remove(image.Asset);
            }

            // Upload new images
            if (request.Images != null && request.Images.Any())
            {
                foreach (var image in request.Images)
                {
                    // Upload to Azure Blob Storage
                    var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                    // Create new asset
                    var asset = new Asset
                    {
                        Url = imageUrl
                    };
                    _context.Assets.Add(asset);
                    
                    // Create news asset relationship
                    var newsAsset = new NewsAsset
                    {
                        NewsId = entity.Id,
                        AssetId = asset.Id
                    };
                    _context.NewsAssets.Add(newsAsset);
                }
            }

            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }
        //BEFORE UPDATE
        protected override Task BeforeUpdate(News entity, NewsUpsertRequest request)
        {
            return base.BeforeUpdate(entity, request);
        }

        //DELETE NEWS
        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.News
                .Include(n => n.NewsAssets)
                .ThenInclude(na => na.Asset)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null)
            {
                throw new UserException("News not found");
            }

            // Delete images from Azure Blob Storage
            foreach (var newsAsset in entity.NewsAssets)
            {
                await _blobStorageService.DeleteAsync(newsAsset.Asset.Url, _containerName);
            }

            await BeforeDelete(entity);
            _context.News.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }   
        
        //MAP TO RESPONSE
        protected override NewsResponse MapToResponse(Database.News entity)
        {
            var response = _mapper.Map<NewsResponse>(entity);
            response.ImageUrls = entity.NewsAssets?.Select(na => na.Asset?.Url).ToList() ?? new List<string>();
            return response;
        }

        //MAP INSERT TO ENTITY
        protected override Database.News MapInsertToEntity(Database.News entity, NewsUpsertRequest request)
        {
            entity.Title = request.Title;
            entity.Content = request.Content;
            entity.VideoURL = request.VideoUrl;
            entity.NewsAssets = new List<NewsAsset>();
            entity.Comments = new List<Comment>();
            entity.CreatedAt = DateTime.UtcNow;
            return entity;
        }
        //BEFORE DELETE
        protected override Task BeforeDelete(News entity)
        {
            return base.BeforeDelete(entity);
        }
        //MAP UPDATE TO ENTITY
        protected override Database.News MapUpdateToEntity(Database.News entity, NewsUpsertRequest request)
        {
            entity.Title = request.Title;
            entity.Content = request.Content;
            entity.VideoURL = request.VideoUrl;
            entity.CreatedAt = DateTime.UtcNow; // Update the creation date
            return entity;
        }
        
    }
}