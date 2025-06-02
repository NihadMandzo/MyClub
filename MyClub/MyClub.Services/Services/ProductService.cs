using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;

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
        public new async Task<PagedResult<ProductResponse>> GetAsync(ProductSearchObject search)
        {
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .AsQueryable();

            // Apply filters
            query = ApplyFilter(query, search);

            // Apply pagination
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
            // Map to response
            var result = new PagedResult<ProductResponse>
            {
                Data = list.Select(x => MapToProductResponse(x)).ToList(),
                TotalCount = await query.CountAsync()
            };

            return result;
        }
        public new async Task<ProductByIdResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(p => p.ProductSizes)
                .ThenInclude(ps => ps.Size)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            return MapToProductByIdResponse(entity);
        }
        protected override IQueryable<Database.Product> ApplyFilter(IQueryable<Database.Product> query, ProductSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Code))
            {
                query = query.Where(x => x.Name.Contains(search.Code));
            }

            if (!string.IsNullOrWhiteSpace(search?.CodeGTE))
            {
                query = query.Where(x => x.Name.CompareTo(search.CodeGTE) >= 0);
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
        protected override async Task BeforeDelete(Database.Product entity)
        {
            // Delete images from Azure Blob Storage
            var assets = await _context.Assets.Include(a => a.ProductAssets).Where(a => a.ProductAssets.Any(pi => pi.ProductId == entity.Id)).ToListAsync();
            foreach (var asset in assets)
            {
                await _blobStorageService.DeleteAsync(asset.Url, _containerName);
            }
            
            // Delete product sizes
            var productSizes = await _context.ProductSizes.Where(ps => ps.ProductId == entity.Id).ToListAsync();
            _context.ProductSizes.RemoveRange(productSizes);
            await _context.SaveChangesAsync();
        }
        public override async Task<ProductResponse> CreateAsync(ProductUpsertRequest request)
        {
            var entity = MapInsertToEntity(new Database.Product(), request);
            await BeforeInsert(entity, request);
            _context.Products.Add(entity);
            await _context.SaveChangesAsync();

            Console.WriteLine($"Product with sizes: {request.ProductSizes.Count}");
            
            // Add more detailed debugging
            if (request.ProductSizes != null)
            {
                Console.WriteLine("Size IDs received:");
                foreach (var size in request.ProductSizes)
                {
                    Console.WriteLine($"  SizeId: {size.SizeId}, Quantity: {size.Quantity}");
                }
            }
            else
            {
                Console.WriteLine("ProductSizes is null");
            }

            // Add product sizes with quantities
            if (request.ProductSizes != null && request.ProductSizes.Count > 0)
            {
                Console.WriteLine($"Adding {request.ProductSizes.Count} product sizes");
                foreach (var sizeRequest in request.ProductSizes)
                {
                    var productSize = new ProductSize
                    {
                        ProductId = entity.Id,
                        SizeId = sizeRequest.SizeId,
                        Quantity = sizeRequest.Quantity
                    };
                    Console.WriteLine($"Adding product size: {productSize.SizeId} - {productSize.Quantity}");
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

            

            return MapToResponse(entity);
        }
        public override async Task<ProductResponse> UpdateAsync(int id, ProductUpsertRequest request)
        {
            var entity = await _context.Products
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(p => p.ProductSizes)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new UserException($"Product with ID {id} not found");

            MapUpdateToEntity(entity, request);
            Console.WriteLine($"Product updated: {entity.Name}, {entity.Id}, {entity.Description}, {entity.Price}, {entity.ColorId}, {entity.CategoryId}, {entity.IsActive}, {entity.CreatedAt}, {entity.UpdatedAt}, {entity.ProductAssets.Count}, {entity.ProductSizes.Count}, {entity.ProductAssets.Count}, {entity.ProductSizes.Count}, {entity.ProductAssets.Count}, {entity.ProductSizes.Count}");
            await BeforeUpdate(entity, request);

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

            // Handle images
            // Delete images not included in ImagesToKeep
            var imagesToDelete = entity.ProductAssets.Where(pa => !request.ImagesToKeep.Contains(pa.AssetId)).ToList();
            foreach (var image in imagesToDelete)
            {
                // Delete from Azure Blob Storage
                await _blobStorageService.DeleteAsync(image.Asset.Url, _containerName);

                // Remove from database
                _context.ProductAssets.Remove(image);
            }

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

            return MapToResponse(entity);
        }
        private async Task<bool> ValidateAsync(ProductUpsertRequest request, int? id = null)
        {
            // Validate category exists
            var categoryExists = await _context.Categories.FindAsync(request.CategoryId) as Category;
            Console.WriteLine($"Category with ID {request.CategoryId} exists: {categoryExists != null}");
            if (categoryExists == null)
            {
                Console.WriteLine($"Category with ID {request.CategoryId} does not exist");
                throw new UserException($"Category with ID {request.CategoryId} does not exist");
            }

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

            return true;
        }
        protected override ProductResponse MapToResponse(Database.Product entity)
        {
            return MapToProductResponse(entity);
        }
        private ProductResponse MapToProductResponse(Database.Product entity)
        {
            var response = _mapper.Map<ProductResponse>(entity);
            response.CategoryName = entity.Category?.Name;
            response.ColorName = entity.Color?.Name;
            response.PrimaryImageUrl = entity.ProductAssets?.FirstOrDefault()?.Asset?.Url;
            return response;
        }
        private ProductByIdResponse MapToProductByIdResponse(Database.Product entity)
        {
            var response = _mapper.Map<ProductByIdResponse>(entity);
            response.CategoryName = entity.Category?.Name;
            response.ColorName = entity.Color?.Name;
            response.PrimaryImageUrl = entity.ProductAssets?.FirstOrDefault()?.Asset?.Url;
            response.ImageUrls = entity.ProductAssets?.Select(pa => pa.Asset?.Url).ToList() ?? new List<string>();
            response.Sizes = entity.ProductSizes?.Select(ps => new ProductSizeResponse
            {
                SizeName = ps.Size?.Name,
                Quantity = ps.Quantity
            }).ToList() ?? new List<ProductSizeResponse>();
            
            return response;
        }
        protected override Database.Product MapInsertToEntity(Database.Product entity, ProductUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
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
            entity.Price = request.Price;
            entity.ColorId = request.ColorId;
            entity.CategoryId = request.CategoryId;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            return entity;
        }
    }
}