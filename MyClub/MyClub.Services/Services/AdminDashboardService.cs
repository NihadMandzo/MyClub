using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;

namespace MyClub.Services.Services
{
    public class AdminDashboardService : IAdminDashboardService
    {
        private readonly MyClubContext _context;

        public AdminDashboardService(MyClubContext context)
        {
            _context = context;
        }

        public async Task<List<DashboardMembershipPerMonthResponse>> MembershipPerMonth()
        {
            var result = await _context.UserMemberships
                .Where(um => um.JoinDate >= DateTime.Now.AddMonths(-12))
                .GroupBy(um => new { 
                    Year = um.JoinDate.Year, 
                    Month = um.JoinDate.Month 
                })
                .Select(g => new DashboardMembershipPerMonthResponse
                {
                    Month = $"{g.Key.Year:0000}-{g.Key.Month:00}",
                    Year = g.Key.Year,
                    MonthName = System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Key.Month),
                    Count = g.Count()
                })
                .OrderBy(x => x.Month)
                .ToListAsync();

            return result;
        }

        public async Task<List<DashboardSalesByCategoryResponse>> SalesPerCategory()
        {
            var totalRevenue = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(p => p.Category)
                .SumAsync(oi => oi.UnitPrice * oi.Quantity);

            var result = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(p => p.Category)
                .GroupBy(oi => new { 
                    CategoryId = oi.ProductSize.Product.CategoryId,
                    CategoryName = oi.ProductSize.Product.Category.Name 
                })
                .Select(g => new DashboardSalesByCategoryResponse
                {
                    CategoryId = g.Key.CategoryId,
                    CategoryName = g.Key.CategoryName,
                    TotalSold = g.Sum(oi => oi.Quantity),
                    TotalRevenue = g.Sum(oi => oi.UnitPrice * oi.Quantity),
                    Percentage = totalRevenue > 0 ? (decimal)(g.Sum(oi => oi.UnitPrice * oi.Quantity) * 100m / totalRevenue) : 0
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToListAsync();

            return result;
        }

        public async Task<List<DashboardRevenuePerMonthResponse>> RevenuePerMonth()
        {
            var result = await _context.Orders
                .Where(o => o.OrderDate >= DateTime.Now.AddMonths(-12))
                .GroupBy(o => new { 
                    Year = o.OrderDate.Year, 
                    Month = o.OrderDate.Month 
                })
                .Select(g => new DashboardRevenuePerMonthResponse
                {
                    Month = $"{g.Key.Year:0000}-{g.Key.Month:00}",
                    Year = g.Key.Year,
                    MonthName = System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Key.Month),
                    TotalAmount = g.Sum(o => o.TotalAmount),
                    Currency = "BAM"
                })
                .OrderBy(x => x.Month)
                .ToListAsync();

            return result;
        }

        public async Task<DashboardCountResponse> MembershipCount()
        {
            var now = DateTime.Now;
            var thisMonthStart = new DateTime(now.Year, now.Month, 1);
            var lastMonthStart = thisMonthStart.AddMonths(-1);

            var totalCount = await _context.UserMemberships.CountAsync();
            var thisMonth = await _context.UserMemberships
                .CountAsync(um => um.JoinDate >= thisMonthStart);
            var lastMonth = await _context.UserMemberships
                .CountAsync(um => um.JoinDate >= lastMonthStart && um.JoinDate < thisMonthStart);

            var percentageChange = lastMonth > 0 ? ((decimal)(thisMonth - lastMonth) / lastMonth) * 100 : 0;

            return new DashboardCountResponse
            {
                TotalCount = totalCount,
                ThisMonth = thisMonth,
                LastMonth = lastMonth,
                PercentageChange = percentageChange
            };
        }

        public async Task<DashboardMostSoldProductResponse> MostSoldProduct()
        {
            var result = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(p => p.Category)
                .Include(oi => oi.ProductSize)
                .ThenInclude(ps => ps.Product)
                .ThenInclude(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .GroupBy(oi => new { 
                    ProductId = oi.ProductSize.Product.Id,
                    ProductName = oi.ProductSize.Product.Name,
                    CategoryName = oi.ProductSize.Product.Category.Name,
                    ImageUrl = oi.ProductSize.Product.ProductAssets
                        .Select(pa => pa.Asset.Url)
                        .FirstOrDefault()
                })
                .Select(g => new DashboardMostSoldProductResponse
                {
                    ProductId = g.Key.ProductId,
                    ProductName = g.Key.ProductName,
                    Category = g.Key.CategoryName,
                    TotalSold = g.Sum(oi => oi.Quantity),
                    TotalRevenue = g.Sum(oi => oi.UnitPrice * oi.Quantity),
                    ImageUrl = g.Key.ImageUrl
                })
                .OrderByDescending(x => x.TotalSold)
                .FirstOrDefaultAsync();

            return result ?? new DashboardMostSoldProductResponse
            {
                ProductId = 0,
                ProductName = "No products sold",
                Category = "N/A",
                TotalSold = 0,
                TotalRevenue = 0,
                ImageUrl = null
            };
        }

        public async Task<DashboardCountResponse> OrderCount()
        {
            var now = DateTime.Now;
            var thisMonthStart = new DateTime(now.Year, now.Month, 1);
            var lastMonthStart = thisMonthStart.AddMonths(-1);

            var totalCount = await _context.Orders.CountAsync();
            var thisMonth = await _context.Orders
                .CountAsync(o => o.OrderDate >= thisMonthStart);
            var lastMonth = await _context.Orders
                .CountAsync(o => o.OrderDate >= lastMonthStart && o.OrderDate < thisMonthStart);

            var percentageChange = lastMonth > 0 ? ((decimal)(thisMonth - lastMonth) / lastMonth) * 100 : 0;

            return new DashboardCountResponse
            {
                TotalCount = totalCount,
                ThisMonth = thisMonth,
                LastMonth = lastMonth,
                PercentageChange = percentageChange
            };
        }

    
    }
}