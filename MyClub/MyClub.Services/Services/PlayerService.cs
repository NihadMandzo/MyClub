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
    public class PlayerService : BaseCRUDService<PlayerResponse, PlayerSearchObject, PlayerInsertRequest, PlayerUpdateRequest, Player>, IPlayerInterface
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private const string _containerName = "players";

        public PlayerService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService) : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
        }

        protected override IQueryable<Player> ApplyFilter(IQueryable<Player> query, PlayerSearchObject search)
        {
            var filteredQuery = base.ApplyFilter(query, search);

            // Add filter by name if provided
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                filteredQuery = filteredQuery.Where(x => 
                    x.FirstName.Contains(search.Name) || 
                    x.LastName.Contains(search.Name));
            }

            // Add filter by club if provided
            if (search.ClubId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.ClubId == search.ClubId.Value);
            }

            // Add filter by position if provided
            if (!string.IsNullOrWhiteSpace(search.Position))
            {
                filteredQuery = filteredQuery.Where(x => x.Position == search.Position);
            }

            // Include related entities if needed
            filteredQuery = filteredQuery.Include(x => x.Club)
                                        .Include(x => x.Image);

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
            await base.BeforeUpdate(entity, request);
            
            // Handle image upload if provided
            if (request.ImageUrl != null)
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
    }
}