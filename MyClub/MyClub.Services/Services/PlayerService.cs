using System;
using System.Linq;
using System.Threading.Tasks;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services.Services
{
    public class PlayerService : BaseCRUDService<PlayerResponse, BaseSearchObject, PlayerInsertRequest, PlayerUpdateRequest, Player>, IPlayerInterface
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private const string _containerName = "players";

        public PlayerService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService) : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
        }

        public override async Task<PagedResult<PlayerResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.Players
                .AsNoTracking()
                .Include(x => x.Club)
                .Include(x => x.Image)
                .AsQueryable();
                
            // Apply filters
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
            
            var list = await query.ToArrayAsync();
            
            return new PagedResult<PlayerResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        protected override IQueryable<Player> ApplyFilter(IQueryable<Player> query, BaseSearchObject search)
        {
            var filteredQuery = base.ApplyFilter(query, search);

            // Add filter by name if provided
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                filteredQuery = filteredQuery.Where(x => 
                    x.FirstName.Contains(search.FTS) || 
                    x.LastName.Contains(search.FTS));
            }

            // Do NOT include related entities here
            return filteredQuery;
        }

        protected override async Task BeforeInsert(Player entity, PlayerInsertRequest request)
        {
            await base.BeforeInsert(entity, request);
            
            // Handle image upload if provided
            if (request.ImageUrl != null)
            {
                // Upload the image to blob storage
                var imageUrl = await _blobStorageService.UploadAsync(request.ImageUrl, _containerName);
                
                // Create a new asset record
                var asset = new Asset
                {
                    Url = imageUrl
                };
                
                _context.Assets.Add(asset);
                await _context.SaveChangesAsync();
                
                // Link the asset to the player
                entity.ImageId = asset.Id;
            }
        }

        protected override async Task BeforeUpdate(Player entity, PlayerUpdateRequest request)
        {
            // Validate that if KeepPicture is false, a new image must be provided
            if (!request.KeepPicture && request.ImageUrl == null)
            {
                throw new UserException("A new image must be provided when not keeping the existing picture.");
            }

            if (!request.KeepPicture && request.ImageUrl != null)
            {
                // If the player already has an image, delete it
                if (entity.ImageId.HasValue)
                {
                    var existingAsset = await _context.Assets.FindAsync(entity.ImageId.Value);
                    if (existingAsset != null)
                    {
                        await _blobStorageService.DeleteAsync(existingAsset.Url, _containerName);
                    }
                }

                // Upload the new image
                var imageUrl = await _blobStorageService.UploadAsync(request.ImageUrl, _containerName);

                // Update or create the asset
                if (entity.ImageId.HasValue)
                {
                    var asset = await _context.Assets.FindAsync(entity.ImageId.Value);
                    if (asset != null)
                    {
                        asset.Url = imageUrl;
                    }
                    else
                    {
                        var newAsset = new Asset
                        {
                            Url = imageUrl
                        };
                        _context.Assets.Add(newAsset);
                        await _context.SaveChangesAsync();
                        entity.ImageId = newAsset.Id;
                    }
                }
                else
                {
                    var newAsset = new Asset
                    {
                        Url = imageUrl
                    };
                    _context.Assets.Add(newAsset);
                    await _context.SaveChangesAsync();
                    entity.ImageId = newAsset.Id;
                }
                await _context.SaveChangesAsync();
            }
            
        }

        protected override PlayerResponse MapToResponse(Player entity)
        {
            var response = base.MapToResponse(entity);
            
            // Calculate age from date of birth if available
            if (entity.DateOfBirth.HasValue)
            {
                var today = DateTime.Today;
                var age = today.Year - entity.DateOfBirth.Value.Year;
                
                // Adjust age if birthday hasn't occurred yet this year
                if (entity.DateOfBirth.Value.Date > today.AddYears(-age))
                {
                    age--;
                }
                
                response.Age = age;
            }
            
            // Set image URL if available
            if (entity.Image != null)
            {
                response.ImageUrl = entity.Image.Url;
            }
            
            return response;
        }
   
        protected override Player MapUpdateToEntity(Player entity, PlayerUpdateRequest request)
        {
            var player = base.MapUpdateToEntity(entity, request);
            player.DateOfBirth = request.DateOfBirth;
            player.Height = request.Height;
            player.Weight = request.Weight;
            player.Biography = request.Biography;
            player.Nationality = request.Nationality;
            player.Position = request.Position;
            player.Number = request.Number;
            player.FirstName = request.FirstName;
            player.LastName = request.LastName;
            player.ClubId = 1;
            player.ImageId = entity.ImageId;

            return player;
        }
        protected override Player MapInsertToEntity(Player entity, PlayerInsertRequest request)
        {
            var player = base.MapInsertToEntity(entity, request);
            player.DateOfBirth = request.DateOfBirth;
            player.Height = request.Height;
            player.Weight = request.Weight;
            player.Biography = request.Biography;
            player.Nationality = request.Nationality;
            player.Position = request.Position;
            player.Number = request.Number;
            player.FirstName = request.FirstName;
            player.LastName = request.LastName;
            player.ClubId = 1;
            return player;
        }
    }
}