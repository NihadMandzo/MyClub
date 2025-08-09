using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyClub.Model.Responses;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model.Requests;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MyClub.Services.Services
{
    public class AdminDashboardService : IAdminDashboardService
    {
        private readonly MyClubContext _context;

        public AdminDashboardService(MyClubContext context)
        {
            _context = context;
            QuestPDF.Settings.License = LicenseType.Community;
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
            var finishedOrderItems = _context.OrderItems
                .Where(oi => oi.Order.OrderState == "Završeno");

            var totalRevenue = await finishedOrderItems
                .SumAsync(oi => oi.UnitPrice * oi.Quantity);

            var rawData = await finishedOrderItems
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
                .Where(o => o.OrderDate >= DateTime.Now.AddMonths(-12)
                            && o.OrderState == "Završeno")
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
                .Where(oi => oi.Order.OrderState == "Završeno")
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

            var finishedOrders = _context.Orders.Where(o => o.OrderState == "Završeno");

            var totalCount = await finishedOrders.CountAsync();
            var thisMonth = await finishedOrders
                .CountAsync(o => o.OrderDate >= thisMonthStart);
            var lastMonth = await finishedOrders
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

        public async Task<byte[]> GenerateDashboardReportAsync(DashboardReportRequest request)
        {
            var topN = 10;

            switch (request.Type)
            {
                case DashboardReportType.Top10MostSoldProducts:
                    {
                        var data = await GetTopProductsAsync(topN, mostSold: true);
                        return BuildTopProductsPdf(data, $"Top {topN} najprodavanijih proizvoda");
                    }
                case DashboardReportType.Top10LeastSoldProducts:
                    {
                        var data = await GetTopProductsAsync(topN, mostSold: false);
                        return BuildTopProductsPdf(data, $"Top {topN} najmanje prodavanih proizvoda");
                    }
                case DashboardReportType.MembershipsPerMonth:
                    {
                        var data = await GetMembershipsPerMonthAsync();
                        return BuildMembershipsPerMonthPdf(data);
                    }
                case DashboardReportType.RevenuePerMonth:
                    {
                        var data = await GetRevenuePerMonthAsync();
                        return BuildRevenuePerMonthPdf(data);
                    }
                default:
                    throw new ArgumentOutOfRangeException(nameof(request.Type), "Unsupported report type");
            }
        }

        private async Task<List<(string Name, string Category, int TotalSold, decimal TotalRevenue)>> GetTopProductsAsync(int topN, bool mostSold)
        {
            var query = _context.OrderItems
                .Where(oi => oi.Order.OrderState == "Završeno")
                .Include(oi => oi.ProductSize)
                    .ThenInclude(ps => ps.Product)
                        .ThenInclude(p => p.Category)
                .GroupBy(oi => new
                {
                    ProductId = oi.ProductSize.Product.Id,
                    ProductName = oi.ProductSize.Product.Name,
                    CategoryName = oi.ProductSize.Product.Category.Name
                })
                .Select(g => new
                {
                    g.Key.ProductName,
                    g.Key.CategoryName,
                    TotalSold = g.Sum(oi => oi.Quantity),
                    TotalRevenue = g.Sum(oi => oi.UnitPrice * oi.Quantity)
                });

            var list = mostSold
                ? await query.OrderByDescending(x => x.TotalSold).Take(topN).ToListAsync()
                : await query.OrderBy(x => x.TotalSold).Take(topN).ToListAsync();

            return list.Select(x => (x.ProductName, x.CategoryName, x.TotalSold, x.TotalRevenue)).ToList();
        }

        private async Task<List<DashboardMembershipPerMonthResponse>> GetMembershipsPerMonthAsync()
        {
            var oneYearAgo = DateTime.Now.AddMonths(-12);

            var raw = await _context.UserMemberships
                .Where(um => um.JoinDate >= oneYearAgo)
                .GroupBy(um => new { um.JoinDate.Year, um.JoinDate.Month })
                .Select(g => new
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    Count = g.Count()
                })
                .OrderBy(x => x.Year)
                .ThenBy(x => x.Month)
                .ToListAsync();

            var result = raw.Select(g => new DashboardMembershipPerMonthResponse
            {
                Month = $"{g.Year:0000}-{g.Month:00}",
                Year = g.Year,
                MonthName = System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Month),
                Count = g.Count
            }).ToList();

            return result;
        }

        private async Task<List<DashboardRevenuePerMonthResponse>> GetRevenuePerMonthAsync()
        {
            var oneYearAgo = DateTime.Now.AddMonths(-12);

            var raw = await _context.Orders
                .Where(o => o.OrderDate >= oneYearAgo && o.OrderState == "Završeno")
                .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
                .Select(g => new
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    TotalAmount = g.Sum(o => o.TotalAmount)
                })
                .OrderBy(x => x.Year)
                .ThenBy(x => x.Month)
                .ToListAsync();

            var result = raw.Select(g => new DashboardRevenuePerMonthResponse
            {
                Month = $"{g.Year:0000}-{g.Month:00}",
                Year = g.Year,
                MonthName = System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(g.Month),
                TotalAmount = g.TotalAmount,
                Currency = "BAM"
            }).ToList();

            return result;
        }

        private byte[] BuildTopProductsPdf(List<(string Name, string Category, int TotalSold, decimal TotalRevenue)> data, string title)
        {
            var now = DateTime.Now;
            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);

                    page.Header().Row(row =>
                    {
                        row.RelativeItem().Text(title).SemiBold().FontSize(18);
                        row.ConstantItem(120).AlignRight().Text($"Datum: {now:dd.MM.yyyy}");
                    });

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(); // #
                            columns.RelativeColumn(4); // Name
                            columns.RelativeColumn(3); // Category
                            columns.RelativeColumn(2); // TotalSold
                            columns.RelativeColumn(2); // TotalRevenue
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(CellHeaderStyle).Text("#");
                            header.Cell().Element(CellHeaderStyle).Text("Proizvod");
                            header.Cell().Element(CellHeaderStyle).Text("Kategorija");
                            header.Cell().Element(CellHeaderStyle).Text("Količina");
                            header.Cell().Element(CellHeaderStyle).Text("Prihod (BAM)");
                        });

                        int i = 1;
                        foreach (var item in data)
                        {
                            table.Cell().Element(CellBodyStyle).Text(i.ToString());
                            table.Cell().Element(CellBodyStyle).Text(item.Name);
                            table.Cell().Element(CellBodyStyle).Text(item.Category);
                            table.Cell().Element(CellBodyStyle).Text(item.TotalSold.ToString());
                            table.Cell().Element(CellBodyStyle).Text(item.TotalRevenue.ToString("0.00"));
                            i++;
                        }

                        static IContainer CellHeaderStyle(IContainer container)
                            => container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(4).PaddingHorizontal(2).Background(Colors.Grey.Lighten3);

                        static IContainer CellBodyStyle(IContainer container)
                            => container.PaddingVertical(2).PaddingHorizontal(2);
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.Span("MyClub - Izvještaj");
                        x.Span("  |  ");
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            });

            return document.GeneratePdf();
        }

        private byte[] BuildMembershipsPerMonthPdf(List<DashboardMembershipPerMonthResponse> data)
        {
            var title = "Broj članova po mjesecima (zadnjih 12 mjeseci)";
            var now = DateTime.Now;

            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);

                    page.Header().Row(row =>
                    {
                        row.RelativeItem().Text(title).SemiBold().FontSize(18);
                        row.ConstantItem(120).AlignRight().Text($"Datum: {now:dd.MM.yyyy}");
                    });

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(3); // Month
                            columns.RelativeColumn(1); // Count
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(CellHeaderStyle).Text("Mjesec");
                            header.Cell().Element(CellHeaderStyle).Text("Broj članova");
                        });

                        foreach (var item in data)
                        {
                            table.Cell().Element(CellBodyStyle).Text($"{item.MonthName} {item.Year}");
                            table.Cell().Element(CellBodyStyle).Text(item.Count.ToString());
                        }

                        static IContainer CellHeaderStyle(IContainer container)
                            => container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(4).PaddingHorizontal(2).Background(Colors.Grey.Lighten3);

                        static IContainer CellBodyStyle(IContainer container)
                            => container.PaddingVertical(2).PaddingHorizontal(2);
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.Span("MyClub - Izvještaj");
                        x.Span("  |  ");
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            });

            return document.GeneratePdf();
        }

        private byte[] BuildRevenuePerMonthPdf(List<DashboardRevenuePerMonthResponse> data)
        {
            var title = "Mjesečna zarada (zadnjih 12 mjeseci)";
            var now = DateTime.Now;

            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);

                    page.Header().Row(row =>
                    {
                        row.RelativeItem().Text(title).SemiBold().FontSize(18);
                        row.ConstantItem(120).AlignRight().Text($"Datum: {now:dd.MM.yyyy}");
                    });

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(3); // Month
                            columns.RelativeColumn(1); // Amount
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(CellHeaderStyle).Text("Mjesec");
                            header.Cell().Element(CellHeaderStyle).Text("Zarada (BAM)");
                        });

                        foreach (var item in data)
                        {
                            table.Cell().Element(CellBodyStyle).Text($"{item.MonthName} {item.Year}");
                            table.Cell().Element(CellBodyStyle).Text(item.TotalAmount.ToString("0.00"));
                        }

                        static IContainer CellHeaderStyle(IContainer container)
                            => container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(4).PaddingHorizontal(2).Background(Colors.Grey.Lighten3);

                        static IContainer CellBodyStyle(IContainer container)
                            => container.PaddingVertical(2).PaddingHorizontal(2);
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.Span("MyClub - Izvještaj");
                        x.Span("  |  ");
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            });

            return document.GeneratePdf();
        }
    }
}
