using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.IO;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Services.Helpers;

namespace MyClub.Services.Services
{
    public class MembershipCardService : BaseCRUDService<MembershipCardResponse, MembershipCardSearchObject, MembershipCardUpsertRequest, MembershipCardUpsertRequest, MembershipCard>, IMembershipCardService
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private const string _containerName = "membership-cards";

        public MembershipCardService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService, IHttpContextAccessor httpContextAccessor)
            : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
            _httpContextAccessor = httpContextAccessor;
        }

        protected override IQueryable<MembershipCard> ApplyFilter(IQueryable<MembershipCard> query, MembershipCardSearchObject search)
        {
            if (search.Year.HasValue)
            {
                query = query.Where(x => x.Year == search.Year.Value);
            }

            if (!string.IsNullOrWhiteSpace(search.NameFTS))
            {
                query = query.Where(x => x.Name.Contains(search.NameFTS));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(x => x.IsActive == search.IsActive.Value);
            }
            else if (!search.IncludeInactive)
            {
                // By default, only return active membership cards
                query = query.Where(x => x.IsActive);
            }

            return query.OrderByDescending(x => x.Year);
        }

        public override async Task<PagedResult<MembershipCardResponse>> GetAsync(MembershipCardSearchObject search)
        {
            var query = _context.MembershipCards
                .AsNoTracking()
                .Include(mc => mc.Image)
                .OrderByDescending(x => x.Year)
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
            
            // Create the paged result with pagination metadata
            return new PagedResult<MembershipCardResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        public override async Task<MembershipCardResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.MembershipCards
                .AsNoTracking()
                .Include(mc => mc.Image)
                .Include(mc => mc.UserMemberships)
                .FirstOrDefaultAsync(mc => mc.Id == id);

            if (entity == null)
            {
                return null;
            }

            return MapToResponse(entity);
        }

        public override async Task<MembershipCardResponse> CreateAsync(MembershipCardUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = MapInsertToEntity(new MembershipCard(), request);
                await BeforeInsert(entity, request);
                _context.MembershipCards.Add(entity);
                await _context.SaveChangesAsync();
                
                // Handle image upload if provided
                if (request.Image != null && request.Image.Length > 0)
                {
                    try
                    {
                        // Upload image to blob storage
                        var imageUrl = await _blobStorageService.UploadAsync(request.Image, _containerName);

                        // Create and save the asset
                        var asset = new Asset
                        {
                            Url = imageUrl
                        };
                        _context.Assets.Add(asset);
                        await _context.SaveChangesAsync();

                        // Link asset to membership card
                        entity.ImageId = asset.Id;
                        entity.Image = asset;
                        await _context.SaveChangesAsync();
                    }
                    catch (Exception)
                    {
                        // Log error and continue without image
                        // In a real app, you would add proper error handling and logging
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

        protected override async Task BeforeInsert(MembershipCard entity, MembershipCardUpsertRequest request)
        {
            // Set the end date to December 31 of the year if not specified
            if (!request.EndDate.HasValue)
            {
                entity.EndDate = new DateTime(request.Year, 12, 31);
            }
            else
            {
                entity.EndDate = request.EndDate.Value;
            }
            
            // Make sure we don't have another active campaign for the same year
            if (entity.IsActive)
            {
                var existingActiveCampaign = await _context.MembershipCards
                    .Where(mc => mc.Year == entity.Year && mc.IsActive)
                    .FirstOrDefaultAsync();
                
                if (existingActiveCampaign != null)
                {
                    existingActiveCampaign.IsActive = false;
                }
            }
        }

        public override async Task<MembershipCardResponse> UpdateAsync(int id, MembershipCardUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.MembershipCards
                    .Include(mc => mc.Image)
                    .FirstOrDefaultAsync(mc => mc.Id == id);

                if (entity == null)
                {
                    throw new Exception("Membership card not found");
                }

                entity = MapUpdateToEntity(entity, request);
                await BeforeUpdate(entity, request);

                // Handle image upload if provided
                if (request.Image != null && request.Image.Length > 0)
                {
                    try
                    {
                        // Check if entity already has an image
                        if (entity.ImageId.HasValue)
                        {
                            var asset = await _context.Assets.FindAsync(entity.ImageId.Value);
                            if (asset != null)
                            {
                                // Delete the old image from blob storage
                                await _blobStorageService.DeleteAsync(asset.Url, _containerName);
                                
                                // Upload the new image
                                var imageUrl = await _blobStorageService.UploadAsync(request.Image, _containerName);
                                
                                // Update the asset URL
                                asset.Url = imageUrl;
                                await _context.SaveChangesAsync();
                            }
                        }
                        else
                        {
                            // Upload the new image
                            var imageUrl = await _blobStorageService.UploadAsync(request.Image, _containerName);
                            
                            // Create and save asset
                            var asset = new Asset
                            {
                                Url = imageUrl
                            };
                            _context.Assets.Add(asset);
                            await _context.SaveChangesAsync();

                            // Link the asset to the membership card
                            entity.ImageId = asset.Id;
                            entity.Image = asset;
                            await _context.SaveChangesAsync();
                        }
                    }
                    catch (Exception)
                    {
                        // Log error and continue without updating the image
                        // In a real app, you would add proper error handling and logging
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return MapToResponse(entity);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        protected override async Task BeforeUpdate(MembershipCard entity, MembershipCardUpsertRequest request)
        {
            // Set the end date if provided
            if (request.EndDate.HasValue)
            {
                entity.EndDate = request.EndDate.Value;
            }
            
            // Make sure we don't have another active campaign for the same year
            if (entity.IsActive)
            {
                var existingActiveCampaigns = await _context.MembershipCards
                    .Where(mc => mc.Year == entity.Year && mc.IsActive && mc.Id != entity.Id)
                    .ToListAsync();
                
                foreach (var campaign in existingActiveCampaigns)
                {
                    campaign.IsActive = false;
                }
            }
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.MembershipCards
                    .Include(mc => mc.Image)
                    .Include(mc => mc.UserMemberships)
                    .FirstOrDefaultAsync(mc => mc.Id == id);

                if (entity == null)
                {
                    throw new Exception("Membership card not found");
                }

                // Check if there are any user memberships
                if (entity.UserMemberships.Any())
                {
                    throw new Exception("Cannot delete membership card with existing user memberships");
                }

                // Delete the image from blob storage if exists
                if (entity.ImageId.HasValue && entity.Image != null)
                {
                    await _blobStorageService.DeleteAsync(entity.Image.Url, _containerName);
                    _context.Assets.Remove(entity.Image);
                }

                await BeforeDelete(entity);
                _context.MembershipCards.Remove(entity);
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

        public async Task<MembershipCardResponse> GetCurrentCampaignAsync()
        {
            var currentYear = DateTime.Now.Year;
            
            var currentCampaign = await _context.MembershipCards
                .Include(mc => mc.Image)
                .Where(mc => mc.IsActive && mc.Year == currentYear)
                .OrderByDescending(mc => mc.StartDate)
                .FirstOrDefaultAsync();
            
            if (currentCampaign == null)
            {
                // Try to get the most recent active campaign from any year
                currentCampaign = await _context.MembershipCards
                    .Include(mc => mc.Image)
                    .Where(mc => mc.IsActive)
                    .OrderByDescending(mc => mc.Year)
                    .ThenByDescending(mc => mc.StartDate)
                    .FirstOrDefaultAsync();
            }
            
            if (currentCampaign == null)
            {
                return null;
            }
            
            var response = MapToResponse(currentCampaign);
            response.IsCurrent = true;
            
            return response;
        }

        public async Task<MembershipCardStatsResponse> GetCampaignStatsAsync(int id)
        {
            var campaign = await _context.MembershipCards
                .Include(mc => mc.UserMemberships)
                .Where(mc => mc.Id == id)
                .FirstOrDefaultAsync();
            
            if (campaign == null)
            {
                return null;
            }
            
            var stats = new MembershipCardStatsResponse
            {
                Id = campaign.Id,
                Name = campaign.Name,
                Year = campaign.Year,
                TotalMembers = campaign.TotalMembers,
                TargetMembers = campaign.TargetMembers,
                NewMemberships = campaign.UserMemberships.Count(um => !um.IsRenewal),
                RenewedMemberships = campaign.UserMemberships.Count(um => um.IsRenewal),
                PhysicalCardsRequested = campaign.UserMemberships.Count(um => um.PhysicalCardRequested),
                PhysicalCardsShipped = campaign.UserMemberships.Count(um => um.IsShipped),
                TotalRevenue = campaign.UserMemberships.Sum(um => um.Payment?.Amount ?? 0)
            };
            
            return stats;
        }

        protected override MembershipCardResponse MapToResponse(MembershipCard entity)
        {
            var response = _mapper.Map<MembershipCardResponse>(entity);
            
            // Add the image URL if available
            if (entity.Image != null)
            {
                response.ImageUrl = entity.Image.Url;
            }
            
            // Check if this is the current campaign
            var currentYear = DateTime.Now.Year;
            response.IsCurrent = entity.IsActive && entity.Year == currentYear;
            
            return response;
        }

        protected override MembershipCard MapInsertToEntity(MembershipCard entity, MembershipCardUpsertRequest request)
        {
            entity.Year = request.Year;
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.TargetMembers = request.TargetMembers;
            entity.Price = request.Price;
            entity.StartDate = request.StartDate;
            entity.Benefits = request.Benefits;
            entity.IsActive = request.IsActive;
            return entity;
        }

        protected override MembershipCard MapUpdateToEntity(MembershipCard entity, MembershipCardUpsertRequest request)
        {
            entity.Year = request.Year;
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.TargetMembers = request.TargetMembers;
            entity.Price = request.Price;
            entity.StartDate = request.StartDate;
            entity.Benefits = request.Benefits;
            entity.IsActive = request.IsActive;
            return entity;
        }
    }
} 