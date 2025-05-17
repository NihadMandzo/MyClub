using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyClub.Services
{
    public class ProductTypeService : IProductTypeService
    {
        private readonly MyClubContext _context;

        public ProductTypeService(MyClubContext context)
        {
            _context = context;
        }

        public async Task<List<ProductTypeResponse>> Get(ProductTypeSearchObject search)
        {
            var query = _context.ProductTypes
                .Include(pt => pt.Products)
                .AsQueryable();

            // Apply filters based on search parameters
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(pt => pt.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(pt => pt.IsActive == search.IsActive.Value);

            // Full-Text Search across multiple fields
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(pt => 
                    pt.Name.Contains(search.FTS) || 
                    pt.Description.Contains(search.FTS));
            }

            var productTypes = await query.ToListAsync();
            return productTypes.Select(MapToResponse).ToList();
        }

        public async Task<List<ProductTypeResponse>> GetAllAsync()
        {
            var productTypes = await _context.ProductTypes
                .Include(pt => pt.Products)
                .ToListAsync();
            
            return productTypes.Select(MapToResponse).ToList();
        }

        public async Task<ProductTypeResponse?> GetByIdAsync(int id)
        {
            var productType = await _context.ProductTypes
                .Include(pt => pt.Products)
                .FirstOrDefaultAsync(pt => pt.Id == id);
            
            return productType != null ? MapToResponse(productType) : null;
        }

        public async Task<ProductTypeResponse> CreateAsync(ProductTypeUpsertRequest request)
        {
            // Check for duplicate name
            if (await _context.ProductTypes.AnyAsync(pt => pt.Name == request.Name))
                throw new InvalidOperationException("Product type with this name already exists");

            // Create new product type entity
            var productType = new ProductType
            {
                Name = request.Name,
                Description = request.Description,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.ProductTypes.Add(productType);
            await _context.SaveChangesAsync();
            
            return MapToResponse(productType);
        }

        public async Task<ProductTypeResponse?> UpdateAsync(int id, ProductTypeUpsertRequest request)
        {
            var existingProductType = await _context.ProductTypes.FindAsync(id);
            
            if (existingProductType == null)
                return null;

            // Check for duplicate name, excluding the current product type
            if (await _context.ProductTypes.AnyAsync(pt => pt.Name == request.Name && pt.Id != id))
                throw new InvalidOperationException("Product type with this name already exists");

            // Update properties
            existingProductType.Name = request.Name;
            existingProductType.Description = request.Description;
            existingProductType.IsActive = request.IsActive;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var productType = await _context.ProductTypes
                .Include(pt => pt.Products)
                .FirstOrDefaultAsync(pt => pt.Id == id);
            
            if (productType == null)
                return false;
                
            // Check if there are any products using this product type
            if (productType.Products.Any())
                throw new InvalidOperationException("Cannot delete product type that is in use by products");

            _context.ProductTypes.Remove(productType);
            await _context.SaveChangesAsync();
            return true;
        }

        // Helper methods
        private ProductTypeResponse MapToResponse(ProductType productType)
        {
            return new ProductTypeResponse
            {
                Id = productType.Id,
                Name = productType.Name,
                Description = productType.Description,
                IsActive = productType.IsActive,
                CreatedAt = productType.CreatedAt,
                ProductCount = productType.Products.Count,
                UpdatedAt = productType.UpdatedAt
            };
        }
    }
} 