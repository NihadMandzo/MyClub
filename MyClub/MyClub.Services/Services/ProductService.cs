using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;
using MyClub.Services.Helpers;

namespace MyClub.Services
{
    public class ProductService : BaseCRUDService<ProductResponse, ProductSearchObject, ProductUpsertRequest, ProductUpsertRequest, Database.Product>, IProductService
    {
        private readonly MyClubContext _context;
        private readonly IBlobStorageService _blobStorageService;
        private const string _containerName = "products";

        public ProductService(MyClubContext context, IMapper mapper, IBlobStorageService blobStorageService) 
            : base(context, mapper)
        {
            _context = context;
            _blobStorageService = blobStorageService;
        }

        // Custom implementation of GetAsync to include related data
        public override async Task<PagedResult<ProductResponse>> GetAsync(ProductSearchObject search)
        {
            var query = _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .AsQueryable();

            // Apply filters
            query = ApplyFilter(query, search);

            int totalCount = 0;
            
            // Get total count if requested
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
            return new PagedResult<ProductResponse>
            {
                Data = list.Select(x => MapToResponse(x)).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        // // Implement the base class method
        public override async Task<ProductResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(p => p.ProductSizes)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }
        
        protected override IQueryable<Database.Product> ApplyFilter(IQueryable<Database.Product> query, ProductSearchObject search)
        {
            // Implement full-text search
            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(p => 
                    p.Name.ToLower().Contains(searchTerm) || 
                    p.Description.ToLower().Contains(searchTerm) ||
                    p.Category.Name.ToLower().Contains(searchTerm) ||
                    p.Color.Name.ToLower().Contains(searchTerm)
                );
            }

            // Filter by barcode
            if (!string.IsNullOrWhiteSpace(search?.BarCode))
            {
                query = query.Where(x => x.BarCode.Contains(search.BarCode));
            }

            // Filter by category IDs
            if (search?.CategoryIds != null && search.CategoryIds.Any())
            {
                query = query.Where(p => search.CategoryIds.Contains(p.CategoryId));
            }

            // Filter by color IDs
            if (search?.ColorIds != null && search.ColorIds.Any())
            {
                query = query.Where(p => search.ColorIds.Contains(p.ColorId));
            }

            // Filter by size IDs
            if (search?.SizeIds != null && search.SizeIds.Any())
            {
                query = query.Where(p => p.ProductSizes.Any(ps => search.SizeIds.Contains(ps.SizeId)));
            }

            // Filter by price range
            if (search?.MinPrice.HasValue == true)
            {
                query = query.Where(p => p.Price >= search.MinPrice.Value);
            }

            if (search?.MaxPrice.HasValue == true)
            {
                query = query.Where(p => p.Price <= search.MaxPrice.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.Product entity, ProductUpsertRequest request)
        {
            await ValidateAsync(request);
            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(Database.Product entity, ProductUpsertRequest request)
        {
            await ValidateAsync(request, entity.Id);
            entity.UpdatedAt = DateTime.UtcNow;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Products
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(p => p.ProductSizes)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (entity == null)
                throw new UserException($"Product with ID {id} not found");

            // Check if the product has related order items
            var hasOrderItems = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                .AnyAsync(oi => oi.ProductSize.ProductId == id);

            if (hasOrderItems)
            {
                // Just mark the product as inactive instead of deleting
                entity.IsActive = false;
                entity.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }

            // For products without order items, perform full deletion
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Get all assets related to this product
                var productAssets = await _context.ProductAssets
                    .Include(pa => pa.Asset)
                    .Where(pa => pa.ProductId == id)
                    .ToListAsync();

                // Get all product sizes to delete
                var productSizes = await _context.ProductSizes
                    .Where(ps => ps.ProductId == id)
                    .ToListAsync();

                // 1. Remove product sizes first
                if (productSizes.Any())
                {
                    _context.ProductSizes.RemoveRange(productSizes);
                    await _context.SaveChangesAsync();
                }

                // 2. Delete product assets from blob storage and remove relationships
                foreach (var productAsset in productAssets)
                {
                    // Delete from Azure Blob Storage if URL exists
                    if (productAsset.Asset != null && !string.IsNullOrEmpty(productAsset.Asset.Url))
                    {
                        await _blobStorageService.DeleteAsync(productAsset.Asset.Url, _containerName);
                    }

                    // Remove the relationship
                    _context.ProductAssets.Remove(productAsset);
                }

                // Save changes to remove relationships
                if (productAssets.Any())
                {
                    await _context.SaveChangesAsync();
                }

                // 3. Delete assets that aren't referenced by other products
                foreach (var productAsset in productAssets)
                {
                    if (productAsset.Asset != null)
                    {
                        var isAssetUsedElsewhere = await _context.ProductAssets
                            .AnyAsync(pa => pa.AssetId == productAsset.AssetId);

                        if (!isAssetUsedElsewhere)
                        {
                            _context.Assets.Remove(productAsset.Asset);
                        }
                    }
                }

                // Save changes after removing assets
                if (productAssets.Any())
                {
                    await _context.SaveChangesAsync();
                }

                // 4. Finally, remove the product entity
                _context.Products.Remove(entity);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                throw new UserException($"Error deleting product: {ex.Message}");
            }
        }

        public override async Task<ProductResponse> CreateAsync(ProductUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = MapInsertToEntity(new Database.Product(), request);
                await BeforeInsert(entity, request);
                _context.Products.Add(entity);
                await _context.SaveChangesAsync();

                // Add product sizes with quantities
                if (request.ProductSizes != null && request.ProductSizes.Count > 0)
                {
                    foreach (var sizeRequest in request.ProductSizes)
                    {
                        var productSize = new ProductSize
                        {
                            ProductId = entity.Id,
                            SizeId = sizeRequest.SizeId,
                            Quantity = sizeRequest.Quantity
                        };
                        await _context.ProductSizes.AddAsync(productSize);
                    }
                    await _context.SaveChangesAsync();
                }

                // Upload images
                if (request.Images != null && request.Images.Any())
                {
                    foreach (var image in request.Images)
                    {
                        // Upload to Azure Blob Storage
                        var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                        // Save image URL to database
                        var asset = new Asset
                        {
                            Url = imageUrl,
                        };
                        
                        // First add and save the asset to get its ID
                        await _context.Assets.AddAsync(asset);
                        await _context.SaveChangesAsync();
                        
                        // Now create the relationship with the valid ID
                        var productAsset = new ProductAsset
                        {
                            ProductId = entity.Id,
                            AssetId = asset.Id
                        };
                        await _context.ProductAssets.AddAsync(productAsset);
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

        public override async Task<ProductResponse> UpdateAsync(int id, ProductUpsertRequest request)
        {
            // Use transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.Products
                    .Include(p => p.ProductAssets)
                    .ThenInclude(pa => pa.Asset)
                    .Include(p => p.ProductSizes)
                    .FirstOrDefaultAsync(x => x.Id == id);

                if (entity == null)
                    throw new UserException($"Product with ID {id} not found");

                await BeforeUpdate(entity, request);
                var updatedEntity = MapUpdateToEntity(entity, request);

                // Update product sizes with quantities
                if (request.ProductSizes != null && request.ProductSizes.Count > 0)
                {
                    // Get existing product sizes
                    var existingSizes = entity.ProductSizes.ToDictionary(ps => ps.SizeId, ps => ps);
                    
                    foreach (var sizeRequest in request.ProductSizes)
                    {
                        // If size already exists for this product, update the quantity
                        if (existingSizes.TryGetValue(sizeRequest.SizeId, out var existingSize))
                        {
                            existingSize.Quantity = sizeRequest.Quantity;
                        }
                        // Otherwise, add a new product size
                        else
                        {
                            var productSize = new ProductSize
                            {
                                ProductId = entity.Id,
                                SizeId = sizeRequest.SizeId,
                                Quantity = sizeRequest.Quantity
                            };
                            await _context.ProductSizes.AddAsync(productSize);
                        }
                    }
                    
                    // Remove sizes that are not in the request
                    var requestSizeIds = request.ProductSizes.Select(ps => ps.SizeId).ToHashSet();
                    var sizesToRemove = entity.ProductSizes.Where(ps => !requestSizeIds.Contains(ps.SizeId)).ToList();
                    
                    foreach (var sizeToRemove in sizesToRemove)
                    {
                        _context.ProductSizes.Remove(sizeToRemove);
                    }
                }
                else
                {
                    // If no sizes are provided, remove all existing sizes
                    _context.ProductSizes.RemoveRange(entity.ProductSizes);
                }

                // Handle images to delete
                var imagesToDelete = entity.ProductAssets
                    .Where(pa => request.ImagesToKeep == null || !request.ImagesToKeep.Contains(pa.AssetId))
                    .ToList();
                
                foreach (var image in imagesToDelete)
                {
                    // Delete from Azure Blob Storage - ensure URL is not null
                    if (image.Asset != null && !string.IsNullOrEmpty(image.Asset.Url))
                    {
                        await _blobStorageService.DeleteAsync(image.Asset.Url, _containerName);
                    }

                    // First remove the relationship
                    _context.ProductAssets.Remove(image);
                }
                
                // Save changes after removing relationships
                await _context.SaveChangesAsync();
                
                // Now remove the assets that are no longer referenced by any product
                foreach (var image in imagesToDelete)
                {
                    if (image.Asset != null)
                    {
                        // Check if this asset is used by any other product before deleting
                        var isAssetUsedElsewhere = await _context.ProductAssets
                            .AnyAsync(pa => pa.AssetId == image.AssetId);
                            
                        if (!isAssetUsedElsewhere)
                        {
                            _context.Assets.Remove(image.Asset);
                        }
                    }
                }
                
                // Save changes after deleting assets
                await _context.SaveChangesAsync();

                // Upload new images
                if (request.Images != null && request.Images.Any())
                {
                    foreach (var image in request.Images)
                    {
                        // Upload to Azure Blob Storage
                        var imageUrl = await _blobStorageService.UploadAsync(image, _containerName);

                        // Save image URL to database
                        var asset = new Asset
                        {
                            Url = imageUrl,
                        };
                        
                        // First add and save the asset to get its ID
                        await _context.Assets.AddAsync(asset);
                        await _context.SaveChangesAsync();
                        
                        // Now create the relationship with the valid ID
                        var productAsset = new ProductAsset
                        {
                            ProductId = entity.Id,
                            AssetId = asset.Id
                        };
                        await _context.ProductAssets.AddAsync(productAsset);
                        await _context.SaveChangesAsync();
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

        private async Task<bool> ValidateAsync(ProductUpsertRequest request, int? id = null)
        {
            // Validate category exists
            var categoryExists = await _context.Categories.FindAsync(request.CategoryId);
            if (categoryExists == null)
            {
                throw new UserException($"Category with ID {request.CategoryId} does not exist");
            }

            // Validate color exists
            var colorExists = await _context.Colors.FindAsync(request.ColorId);
            if (colorExists == null)
                throw new UserException($"Color with ID {request.ColorId} does not exist");

            // Validate sizes exist
            if (request.ProductSizes != null && request.ProductSizes.Count > 0)
            {
                foreach (var sizeRequest in request.ProductSizes)
                {
                    var sizeExists = await _context.Sizes.AnyAsync(s => s.Id == sizeRequest.SizeId);
                    if (!sizeExists)
                        throw new UserException($"Size with ID {sizeRequest.SizeId} does not exist");
                }
            }

            // Validate image IDs to keep exist and belong to this product
            if (id.HasValue && request.ImagesToKeep != null && request.ImagesToKeep.Any())
            {
                foreach (var imageId in request.ImagesToKeep)
                {
                    var imageExists = await _context.Assets.AnyAsync(a => a.Id == imageId && a.ProductAssets.Any(pi => pi.ProductId == id));
                    if (!imageExists)
                        throw new UserException($"Image with ID {imageId} does not exist or does not belong to this product");
                }
            }

            // Validate name is unique
            var nameExists = await _context.Products
                .AnyAsync(p => p.Name == request.Name && (id == null || p.Id != id));
                
            if (nameExists)
                throw new UserException($"Product with name '{request.Name}' already exists");

            // Validate barcode is unique if provided
            if (!string.IsNullOrWhiteSpace(request.BarCode))
            {
                var barcodeExists = await _context.Products
                    .AnyAsync(p => p.BarCode == request.BarCode && (id == null || p.Id != id));
                    
                if (barcodeExists)
                    throw new UserException($"Product with barcode '{request.BarCode}' already exists");
            }

            return true;
        }


        // Fix the MapToResponse method to handle null references
        private ProductResponse MapToResponse(Database.Product entity)
        {
            var response = _mapper.Map<ProductResponse>(entity);
            
            // Handle Category
            if (entity.Category != null)
            {
                response.Category = new CategoryResponse
                {
                    Id = entity.Category.Id,
                    Name = entity.Category.Name
                };
            }
            
            // Handle Color
            if (entity.Color != null)
            {
                response.Color = new ColorResponse
                {
                    Id = entity.Color.Id,
                    Name = entity.Color.Name
                };
            }
            
            // Handle PrimaryImageUrl safely
            var firstProductAsset = entity.ProductAssets?.FirstOrDefault();
            if (firstProductAsset != null && firstProductAsset.Asset != null)
            {
                response.PrimaryImageUrl = new AssetResponse
                {
                    Id = firstProductAsset.Asset.Id,
                    ImageUrl = firstProductAsset.Asset.Url
                };
            }
            
            // Handle ImageUrls safely
            response.ImageUrls = entity.ProductAssets?
                .Where(pa => pa.Asset != null)
                .Select(pa => new AssetResponse
                {
                    Id = pa.Asset.Id,
                    ImageUrl = pa.Asset.Url
                })
                .ToList() ?? new List<AssetResponse>();
            
            // Handle Sizes safely
            response.Sizes = entity.ProductSizes?
                .Where(ps => ps.Size != null)
                .Select(ps => new ProductSizeResponse
                {
                    Size = new SizeResponse
                    {
                        Id = ps.Size.Id,
                        Name = ps.Size.Name
                    },
                    Quantity = ps.Quantity
                })
                .ToList() ?? new List<ProductSizeResponse>();
            
            return response;
        }


        protected override Database.Product MapInsertToEntity(Database.Product entity, ProductUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.BarCode = request.BarCode;
            entity.Price = request.Price;
            entity.ColorId = request.ColorId;
            entity.CategoryId = request.CategoryId;
            entity.IsActive = request.IsActive;
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.ProductAssets = new List<ProductAsset>();
            entity.ProductSizes = new List<ProductSize>();
            return entity;
        }

        protected override Database.Product MapUpdateToEntity(Database.Product entity, ProductUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.BarCode = request.BarCode;
            entity.Price = request.Price;
            entity.ColorId = request.ColorId;
            entity.CategoryId = request.CategoryId;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            return entity;
        }
    }
}