using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MyClub.Model.Responses;

namespace MyClub.Services.Interfaces
{
    public interface IAdminDashboardService
    {
        Task<List<DashboardMembershipPerMonthResponse>> MembershipPerMonth();

        Task<List<DashboardSalesByCategoryResponse>> SalesPerCategory();

        Task<List<DashboardRevenuePerMonthResponse>> RevenuePerMonth();

        Task<DashboardCountResponse> MembershipCount();

        Task<DashboardMostSoldProductResponse> MostSoldProduct();

        Task<DashboardCountResponse> OrderCount();
    }
}