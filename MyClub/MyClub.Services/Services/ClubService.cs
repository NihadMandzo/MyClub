using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model.Requests;
using MyClub.Model.Responses;   
using MyClub.Model.SearchObjects;
using MapsterMapper;

namespace MyClub.Services.Services
{
    public class ClubService : BaseCRUDService<ClubResponse, BaseSearchObject, ClubRequest, ClubRequest, Club>, IClubService
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private readonly string _containerName = "club";

        public ClubService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService) : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
        }

        public override async Task<ClubResponse> CreateAsync(ClubRequest request)
        {
            var entity = new Club();
            MapInsertToEntity(entity, request);
            await BeforeInsert(entity, request);
            _context.Clubs.Add(entity);
            await _context.SaveChangesAsync();

            return MapToResponse(entity);
        }

        public override async Task<ClubResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Clubs
                .Include(x => x.LogoImage)
                .FirstOrDefaultAsync(c => c.Id == id);
                
            if (entity == null)
                throw new UserException($"Club with id {id} not found");

            return MapToResponse(entity);
        }

        protected override ClubResponse MapToResponse(Club entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));
            var response = _mapper.Map<ClubResponse>(entity);
            response.ImageUrl = entity.LogoImage?.Url;
            return response;
        }

        protected override Club MapInsertToEntity(Club entity, ClubRequest request)
        {
            if (entity == null) throw new ArgumentNullException(nameof(entity));
            if (request == null) throw new ArgumentNullException(nameof(request));

            entity.Name = request.Name;
            entity.Description = request.Description;
            // LogoImage will be handled separately in the file upload logic

            return entity;
        }

        protected override Club MapUpdateToEntity(Club entity, ClubRequest request)
        {
            if (entity == null) throw new ArgumentNullException(nameof(entity));
            if (request == null) throw new ArgumentNullException(nameof(request));

            entity.Name = request.Name;
            entity.Description = request.Description;
            // LogoImage will be handled separately in the file upload logic

            return entity;
        }

        protected override async Task BeforeInsert(Club entity, ClubRequest request)
        {
            if (request.LogoImage != null && request.LogoImage.Length > 0)
            {
                // Upload logo image to blob storage
                string logoUrl = await _blobStorageService.UploadAsync(request.LogoImage, _containerName);

                // Create a new Asset entity and associate it with the Club
                var asset = new Asset
                {
                    Url = logoUrl
                };

                // Set the relationship
                entity.LogoImage = asset;
            }
        }

        protected override async Task BeforeUpdate(Club entity, ClubRequest request)
        {
            if (request.LogoImage != null && request.LogoImage.Length > 0)
            {
                // If there's an existing logo, delete it
                if (entity.LogoImage != null && !string.IsNullOrEmpty(entity.LogoImage.Url))
                {
                    await _blobStorageService.DeleteAsync(entity.LogoImage.Url, _containerName);

                    // Upload new logo image and update the existing Asset
                    string logoUrl = await _blobStorageService.UploadAsync(request.LogoImage, _containerName);
                    entity.LogoImage.Url = logoUrl;
                }
                else
                {
                    // Upload new logo image and create a new Asset
                    string logoUrl = await _blobStorageService.UploadAsync(request.LogoImage, _containerName);

                    // Create a new Asset entity and associate it with the Club
                    var asset = new Asset
                    {
                        Url = logoUrl
                    };

                    // Set the relationship
                    entity.LogoImage = asset;
                }
            }
        }

        protected override async Task<bool> BeforeDelete(Club entity)
        {
            // Delete the logo image if it exists
            if (!string.IsNullOrEmpty(entity.LogoImage?.Url))
            {
                await _blobStorageService.DeleteAsync(entity.LogoImage.Url, _containerName);
            }

            // Check if the club has any players or matches before deletion
            if (entity.Players.Count > 0 || entity.Matches.Count > 0)
            {
                throw new Exception("Cannot delete club with associated players or matches.");
            }
            return await Task.FromResult(true);
        }

        public override async Task<PagedResult<ClubResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.Clubs.Include(c => c.LogoImage).AsQueryable();

            // Apply search filters
            query = ApplyFilter(query, search);

            // Get total count before pagination
            int totalCount = 0;
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

            return new PagedResult<ClubResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        protected override IQueryable<Club> ApplyFilter(IQueryable<Club> query, BaseSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                query = query.Where(c => c.Name.Contains(search.FTS) || c.Description.Contains(search.FTS));
            }
            return query;
        }

        public override async Task<ClubResponse> UpdateAsync(int id, ClubRequest request)
        {
            var entity = await _context.Clubs
                .Include(c => c.LogoImage)
                .FirstOrDefaultAsync(c => c.Id == id);
                
            if (entity == null)
                throw new Exception($"Club with id {id} not found");

            entity = MapUpdateToEntity(entity, request);
            await BeforeUpdate(entity, request);
            _context.Clubs.Update(entity);
            await _context.SaveChangesAsync();

            return MapToResponse(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Clubs
                .Include(c => c.LogoImage)
                .FirstOrDefaultAsync(c => c.Id == id);
                
            if (entity == null)
                throw new Exception($"Club with id {id} not found");

            await BeforeDelete(entity);
            _context.Clubs.Remove(entity);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}