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
            var query = _context.News
                .AsNoTracking() // Add AsNoTracking for read-only operations
                .Include(n => n.NewsAssets)
                .ThenInclude(n => n.Asset)
                .Include(n => n.Comments)
                .ThenInclude(c => c.User)
                .Include(n => n.User)
                .OrderByDescending(x => x.CreatedAt)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int totalCount = 0;

            // Always get total count before pagination
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;

            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();

            // Create the paged result with enhanced pagination metadata
            return new PagedResult<NewsResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        //APPLY FILTER
        protected override IQueryable<Database.News> ApplyFilter(IQueryable<Database.News> query, NewsSearchObject search)
        {
            // Implement full-text search
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(n =>
                    n.Title.ToLower().Contains(searchTerm) ||
                    n.Content.ToLower().Contains(searchTerm)
                );
            }

            return query;
        }

        //GET NEWS BY ID
        public override async Task<NewsResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.News
                .AsNoTracking() // Add AsNoTracking for read-only operations
                .Include(n => n.NewsAssets)
                .ThenInclude(x => x.Asset)
                .Include(n => n.Comments)
                .ThenInclude(c => c.User)
                .Include(n => n.User)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null)
            {
                return null;
            }
            return MapToResponse(entity);
        }

        //CREATE NEWS
        public override async Task<NewsResponse> CreateAsync(NewsUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = MapInsertToEntity(new Database.News(), request);
                await BeforeInsert(entity, request);
                _context.News.Add(entity);
                await _context.SaveChangesAsync();

                if (request.Images != null && request.Images.Any())
                {
                    foreach (var image in request.Images)
                    {
                        var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                        var asset = new Asset()
                        {
                            Url = imageUrl
                        };
                        await _context.Assets.AddAsync(asset);
                        await _context.SaveChangesAsync();

                        var newsAsset = new NewsAsset()
                        {
                            NewsId = entity.Id,
                            AssetId = asset.Id
                        };
                        await _context.NewsAssets.AddAsync(newsAsset);
                        await _context.SaveChangesAsync();
                    }
                }

                await transaction.CommitAsync();
                return MapToResponse(entity);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        //BEFORE INSERT
        protected override Task BeforeInsert(News entity, NewsUpsertRequest request)
        {
            ValidateNewsRequest(request);

            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
            {
                throw new UserException("No HTTP context available");
            }

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
            {
                throw new UserException("No authorization header found");
            }

            entity.UserId = JwtTokenManager.GetUserIdFromToken(authHeader);
            entity.CreatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }

        //UPDATE NEWS
        public override async Task<NewsResponse> UpdateAsync(int id, NewsUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.News
                    .Include(n => n.NewsAssets)
                    .ThenInclude(na => na.Asset)
                    .FirstOrDefaultAsync(n => n.Id == id);

                await BeforeUpdate(entity, request);
                var updatedEntity = MapUpdateToEntity(entity, request);

                // Handle images to delete
                var imagesToDelete = updatedEntity.NewsAssets
                    .Where(na => request.ImagesToKeep == null || !request.ImagesToKeep.Contains(na.AssetId))
                    .ToList();

                foreach (var image in imagesToDelete)
                {
                    // Delete from Azure Blob Storage
                    await _blobStorageService.DeleteAsync(image.Asset.Url, _containerName);

                    // Remove from database
                    _context.NewsAssets.Remove(image);
                    _context.Assets.Remove(image.Asset);
                }

                // Save changes after deleting to avoid conflicts
                await _context.SaveChangesAsync();

                // Upload and save new images
                if (request.Images != null && request.Images.Any())
                {
                    foreach (var image in request.Images)
                    {
                        // Upload to Azure Blob Storage
                        var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                        // Create and save new asset first
                        var asset = new Asset
                        {
                            Url = imageUrl
                        };
                        _context.Assets.Add(asset);
                        await _context.SaveChangesAsync(); // Save to get the Asset Id

                        // Now create the relationship with valid AssetId
                        var newsAsset = new NewsAsset
                        {
                            NewsId = entity.Id,
                            AssetId = asset.Id
                        };
                        _context.NewsAssets.Add(newsAsset);
                        await _context.SaveChangesAsync();
                    }
                }

                await transaction.CommitAsync();
                return MapToResponse(entity);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        //BEFORE UPDATE
        protected override Task BeforeUpdate(News entity, NewsUpsertRequest request)
        {
            if (entity == null)
            {
                throw new UserException("News not found");
            }

            ValidateNewsRequest(request);
            return Task.CompletedTask;
        }

        //DELETE NEWS
        public override async Task<bool> DeleteAsync(int id)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
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
                // Remove news assets and assets from the database
                _context.NewsAssets.RemoveRange(entity.NewsAssets);
                _context.Assets.RemoveRange(entity.NewsAssets.Select(na => na.Asset));

                // Remove comments associated with the news
                _context.Comments.RemoveRange(entity.Comments);

                // Remove the news entity
                await BeforeDelete(entity);
                _context.News.Remove(entity);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        //MAP TO RESPONSE
        protected override NewsResponse MapToResponse(Database.News entity)
        {
            var response = new NewsResponse
            {
                Id = entity.Id,
                Title = entity.Title,
                Date = entity.CreatedAt,
                PrimaryImage = entity.NewsAssets?
                    .Where(na => na.Asset?.Url != null)
                    .Select(na => new AssetResponse
                    {
                        Id = na.Asset.Id,
                        ImageUrl = na.Asset!.Url!
                    })
                    .FirstOrDefault(),
                VideoUrl = entity.VideoURL,
                Content = entity.Content,
                Username = entity.User?.Username ?? string.Empty,
                Images = entity.NewsAssets?
                    .Where(na => na.Asset?.Url != null)
                    .Select(na => new AssetResponse
                    {
                        Id = na.Asset.Id,
                        ImageUrl = na.Asset!.Url!
                    })
                    .ToList() ?? new List<AssetResponse>(),
                Comments = entity.Comments?
                    .Select(c => new CommentResponse
                    {
                        Id = c.Id,
                        Content = c.Content,
                        CreatedAt = c.CreatedAt,
                        Username = c.User?.Username ?? string.Empty
                    })
                    .ToList() ?? new List<CommentResponse>()
            };
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
        protected override News MapUpdateToEntity(News entity, NewsUpsertRequest request)
        {
            entity.Title = request.Title;
            entity.Content = request.Content;
            entity.VideoURL = request.VideoUrl;
            entity.CreatedAt = DateTime.UtcNow; // Update the creation date
            return entity;
        }

        private void ValidateNewsRequest(NewsUpsertRequest request)
        {
            // Title validation
            if (string.IsNullOrWhiteSpace(request.Title))
            {
                throw new UserException("Title is required");
            }

            if (request.Title.Length > 200)
            {
                throw new UserException("Title cannot exceed 200 characters");
            }

            if (request.Title.Length < 3)
            {
                throw new UserException("Title must be at least 3 characters long");
            }

            // Content validation
            if (string.IsNullOrWhiteSpace(request.Content))
            {
                throw new UserException("Content is required");
            }

            if (request.Content.Length < 10)
            {
                throw new UserException("Content must be at least 10 characters long");
            }

            // Video URL validation
            if (!string.IsNullOrWhiteSpace(request.VideoUrl) && request.VideoUrl.Length > 255)
            {
                throw new UserException("Video URL cannot exceed 255 characters");
            }

            bool hasNoImages = (request.Images == null || request.Images.Count == 0);
            bool hasNoImagesToKeep = (request.ImagesToKeep == null || request.ImagesToKeep.Count == 0);

            if (request.Images != null)
            {
                foreach (var image in request.Images)
                {
                    if (image == null || image.Length == 0)
                    {
                        throw new UserException("Empty image file detected");
                    }

                    if (image.Length > 10 * 1024 * 1024) // 10 MB limit
                    {
                        throw new UserException("Image size cannot exceed 10MB");
                    }

                    var extension = Path.GetExtension(image.FileName).ToLower();
                    if (!new[] { ".jpg", ".jpeg", ".png" }.Contains(extension))
                    {
                        throw new UserException("Only .jpg, .jpeg and .png files are allowed");
                    }
                }
            }
        }
    }
}