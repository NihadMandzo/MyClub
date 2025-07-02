// using Microsoft.AspNetCore.Authorization;
// using Microsoft.AspNetCore.Mvc;
// using MyClub.Model.Responses;
// using MyClub.Services.Interfaces;
// using System;
// using System.Collections.Generic;
// using System.Threading.Tasks;

// namespace MyClub.WebAPI.Controllers
// {
//     [ApiController]
//     [Route("api/[controller]")]
//     [Authorize(Policy = "AdminOnly")]
//     public class AdminDashboardController : ControllerBase
//     {
//         private readonly IAdminDashboardService _adminDashboardService;

//         public AdminDashboardController(IAdminDashboardService adminDashboardService)
//         {
//             _adminDashboardService = adminDashboardService;
//         }

//         /// <summary>
//         /// Get memberships count per month for the last 12 months
//         /// </summary>
//         [HttpGet("memberships-per-month")]
//         public async Task<ActionResult<List<DashboardMembershipPerMonthResponse>>> GetMembershipsPerMonth()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.MembershipPerMonth();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }

//         /// <summary>
//         /// Get sales data grouped by product category
//         /// </summary>
//         [HttpGet("sales-per-category")]
//         public async Task<ActionResult<List<DashboardSalesByCategoryResponse>>> GetSalesPerCategory()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.SalesPerCategory();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }

//         /// <summary>
//         /// Get revenue per month for the last 12 months
//         /// </summary>
//         [HttpGet("revenue-per-month")]
//         public async Task<ActionResult<List<DashboardRevenuePerMonthResponse>>> GetRevenuePerMonth()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.RevenuePerMonth();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }

//         /// <summary>
//         /// Get total membership count with monthly comparison
//         /// </summary>
//         [HttpGet("membership-count")]
//         public async Task<ActionResult<DashboardCountResponse>> GetMembershipCount()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.MembershipCount();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }

//         /// <summary>
//         /// Get the most sold product
//         /// </summary>
//         [HttpGet("most-sold-product")]
//         public async Task<ActionResult<DashboardMostSoldProductResponse>> GetMostSoldProduct()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.MostSoldProduct();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }

//         /// <summary>
//         /// Get total order count with monthly comparison
//         /// </summary>
//         [HttpGet("order-count")]
//         public async Task<ActionResult<DashboardCountResponse>> GetOrderCount()
//         {
//             try
//             {
//                 var result = await _adminDashboardService.OrderCount();
//                 return Ok(new { success = true, data = result });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }


//         /// <summary>
//         /// Get all dashboard data in one request
//         /// </summary>
//         [HttpGet("overview")]
//         public async Task<ActionResult> GetDashboardOverview()
//         {
//             try
//             {
//                 var membershipsPerMonth = await _adminDashboardService.MembershipPerMonth();
//                 var salesPerCategory = await _adminDashboardService.SalesPerCategory();
//                 var revenuePerMonth = await _adminDashboardService.RevenuePerMonth();
//                 var membershipCount = await _adminDashboardService.MembershipCount();
//                 var mostSoldProduct = await _adminDashboardService.MostSoldProduct();
//                 var orderCount = await _adminDashboardService.OrderCount();

//                 var overview = new
//                 {
//                     membershipsPerMonth,
//                     salesPerCategory,
//                     revenuePerMonth,
//                     membershipCount,
//                     mostSoldProduct,
//                     orderCount
//                 };

//                 return Ok(new { success = true, data = overview });
//             }
//             catch (Exception ex)
//             {
//                 return BadRequest(new { success = false, message = ex.Message });
//             }
//         }
//     }
// } 