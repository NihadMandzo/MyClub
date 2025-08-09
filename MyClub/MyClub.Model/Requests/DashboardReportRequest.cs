using System;

namespace MyClub.Model.Requests
{
    /// <summary>
    /// Type of dashboard report to generate.
    /// </summary>
    public enum DashboardReportType
    {
        Top10MostSoldProducts = 1,
        Top10LeastSoldProducts = 2,
        MembershipsPerMonth = 3,
        RevenuePerMonth = 4
    }

    /// <summary>
    /// Request model used when generating a dashboard PDF.
    /// For now it only contains the report type but can be extended
    /// with date ranges, filters, localization, etc.
    /// </summary>
    public class DashboardReportRequest
    {
        public DashboardReportType Type { get; set; }
    }
}
