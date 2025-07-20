using System;
using System.Collections.Generic;
using System.Globalization;
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
            var rawData = await _context.UserMemberships
                .Where(um => um.JoinDate >= DateTime.Now.AddMonths(-12))
                .GroupBy(um => new
                {
                    Year = um.JoinDate.Year,
                    Month = um.JoinDate.Month
                })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    Count = g.Count()
                })
                .ToListAsync();

            var result = rawData
                .Select(g => new DashboardMembershipPerMonthResponse
                {
                    Month = $"{g.Year:0000}-{g.Month:00}",
                    Year = g.Year,
                    MonthName = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Month),
                    Count = g.Count
                })
                .OrderBy(x => x.Month)
                .ToList();

            return result;
        }

        public async Task<List<DashboardSalesByCategoryResponse>> SalesPerCategory()
        {
            var totalRevenue = await _context.OrderItems
                .SumAsync(oi => oi.UnitPrice * oi.Quantity);

            var rawData = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                    .ThenInclude(ps => ps.Product)
                        .ThenInclude(p => p.Category)
                .GroupBy(oi => new
                {
                    CategoryId = oi.ProductSize.Product.CategoryId,
                    CategoryName = oi.ProductSize.Product.Category.Name
                })
                .Select(g => new
                {
                    g.Key.CategoryId,
                    g.Key.CategoryName,
                    TotalSold = g.Sum(oi => oi.Quantity),
                    TotalRevenue = g.Sum(oi => oi.UnitPrice * oi.Quantity)
                })
                .ToListAsync();

            var result = rawData
                .Select(g => new DashboardSalesByCategoryResponse
                {
                    CategoryId = g.CategoryId,
                    CategoryName = g.CategoryName,
                    TotalSold = g.TotalSold,
                    TotalRevenue = g.TotalRevenue,
                    Percentage = totalRevenue > 0 ? (g.TotalRevenue * 100m / totalRevenue) : 0
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToList();

            return result;
        }

        public async Task<List<DashboardRevenuePerMonthResponse>> RevenuePerMonth()
        {
            var rawData = await _context.Orders
                .Where(o => o.OrderDate >= DateTime.Now.AddMonths(-12))
                .GroupBy(o => new
                {
                    Year = o.OrderDate.Year,
                    Month = o.OrderDate.Month
                })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    TotalAmount = g.Sum(o => o.TotalAmount)
                })
                .ToListAsync();

            var result = rawData
                .Select(g => new DashboardRevenuePerMonthResponse
                {
                    Month = $"{g.Year:0000}-{g.Month:00}",
                    Year = g.Year,
                    MonthName = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Month),
                    TotalAmount = g.TotalAmount,
                    Currency = "BAM"
                })
                .OrderBy(x => x.Month)
                .ToList();

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
            var rawData = await _context.OrderItems
                .Include(oi => oi.ProductSize)
                    .ThenInclude(ps => ps.Product)
                        .ThenInclude(p => p.Category)
                .Include(oi => oi.ProductSize)
                    .ThenInclude(ps => ps.Product)
                        .ThenInclude(p => p.ProductAssets)
                            .ThenInclude(pa => pa.Asset)
                .GroupBy(oi => new
                {
                    ProductId = oi.ProductSize.Product.Id,
                    ProductName = oi.ProductSize.Product.Name,
                    CategoryName = oi.ProductSize.Product.Category.Name,
                    ImageUrl = oi.ProductSize.Product.ProductAssets
                        .Select(pa => pa.Asset.Url)
                        .FirstOrDefault()
                })
                .Select(g => new
                {
                    g.Key.ProductId,
                    g.Key.ProductName,
                    g.Key.CategoryName,
                    g.Key.ImageUrl,
                    TotalSold = g.Sum(oi => oi.Quantity),
                    TotalRevenue = g.Sum(oi => oi.UnitPrice * oi.Quantity)
                })
                .OrderByDescending(x => x.TotalSold)
                .FirstOrDefaultAsync();

            if (rawData == null)
            {
                return new DashboardMostSoldProductResponse
                {
                    ProductId = 0,
                    ProductName = "No products sold",
                    Category = "N/A",
                    TotalSold = 0,
                    TotalRevenue = 0,
                    ImageUrl = null
                };
            }

            return new DashboardMostSoldProductResponse
            {
                ProductId = rawData.ProductId,
                ProductName = rawData.ProductName,
                Category = rawData.CategoryName,
                TotalSold = rawData.TotalSold,
                TotalRevenue = rawData.TotalRevenue,
                ImageUrl = rawData.ImageUrl
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
