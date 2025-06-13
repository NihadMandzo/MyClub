using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
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
    public class UserMembershipService : BaseCRUDService<UserMembershipResponse, UserMembershipSearchObject, UserMembershipUpsertRequest, UserMembershipUpsertRequest, UserMembership>, IUserMembershipService
    {
        private readonly MyClubContext _context;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IPaymentService _paymentService;
        public UserMembershipService(MyClubContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IPaymentService paymentService)
            : base(context, mapper)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
            _paymentService = paymentService;
        }

        protected override IQueryable<UserMembership> ApplyFilter(IQueryable<UserMembership> query, UserMembershipSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(x => x.UserId == search.UserId.Value);
            }

            if (search.MembershipCardId.HasValue)
            {
                query = query.Where(x => x.MembershipCardId == search.MembershipCardId.Value);
            }

            if (search.IsRenewal.HasValue)
            {
                query = query.Where(x => x.IsRenewal == search.IsRenewal.Value);
            }

            if (search.PhysicalCardRequested.HasValue)
            {
                query = query.Where(x => x.PhysicalCardRequested == search.PhysicalCardRequested.Value);
            }

            if (search.IsShipped.HasValue)
            {
                query = query.Where(x => x.IsShipped == search.IsShipped.Value);
            }

            if (search.IsPaid.HasValue)
            {
                query = query.Where(x => x.IsPaid == search.IsPaid.Value);
            }

            return query.OrderByDescending(x => x.JoinDate);
        }

        public override async Task<PagedResult<UserMembershipResponse>> GetAsync(UserMembershipSearchObject search)
        {
            var query = _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .OrderByDescending(x => x.JoinDate)
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
            
            return new PagedResult<UserMembershipResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }

        public override async Task<UserMembershipResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .FirstOrDefaultAsync(um => um.Id == id);

            if (entity == null)
            {
                return null;
            }

            return MapToResponse(entity);
        }

        public async Task<List<UserMembershipResponse>> GetUserMembershipsAsync(int userId)
        {
            var memberships = await _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .Where(um => um.UserId == userId)
                .OrderByDescending(um => um.MembershipCard.Year)
                .ThenByDescending(um => um.JoinDate)
                .ToListAsync();

            return memberships.Select(MapToResponse).ToList();
        }

        public async Task<UserMembershipResponse> PurchaseMembershipAsync(UserMembershipUpsertRequest request)
        {
            // Get the current user ID from the token
            var userId = GetCurrentUserId();
            
            // Get the membership card
            var membershipCard = await _context.MembershipCards
                .FirstOrDefaultAsync(mc => mc.Id == request.MembershipCardId);
                
            if (membershipCard == null)
            {
                throw new Exception("Membership card not found");
            }
            
            // Check if the membership card is active
            if (!membershipCard.IsActive)
            {
                throw new Exception("This membership campaign is no longer active");
            }

            // Validate the request
            request.Validate();

            // Check for existing membership (except for gift purchases)
            if (request.OperationType != MembershipOperationType.GiftPurchase)
            {
                var existingMembership = await _context.UserMemberships
                    .Where(um => um.UserId == userId && um.MembershipCardId == request.MembershipCardId)
                    .FirstOrDefaultAsync();
                    
                if (existingMembership != null)
                {
                    throw new Exception("You already have a membership for this campaign");
                }
            }

            // For renewals, verify the previous membership
            if (request.OperationType == MembershipOperationType.Renewal)
            {
                var previousMembership = await _context.UserMemberships
                    .FirstOrDefaultAsync(um => um.Id == request.PreviousMembershipId && um.UserId == userId);
                    
                if (previousMembership == null)
                {
                    throw new Exception("Previous membership not found");
                }
            }
            
            // Create a payment record first
            string paymentId;
            try
            {
                // Use the payment service to create a payment
                if (request.Method.ToLower() == "stripe")
                {
                    paymentId = await _paymentService.CreateStripePaymentAsync(request);
                }
                else if (request.Method.ToLower() == "paypal")
                {
                    paymentId = await _paymentService.CreatePayPalPaymentAsync(request);
                }
                else
                {
                    throw new Exception($"Unsupported payment method: {request.Method}");
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to process payment: {ex.Message}");
            }
            
            // Create the user membership
            var userMembership = new UserMembership
            {
                UserId = userId,
                MembershipCardId = request.MembershipCardId,
                JoinDate = DateTime.UtcNow,
                IsRenewal = request.OperationType == MembershipOperationType.Renewal,
                PreviousMembershipId = request.PreviousMembershipId,
                PhysicalCardRequested = request.PhysicalCardRequested,
                IsPaid = true,
                PaymentDate = DateTime.UtcNow,
                PaymentId = Guid.Parse(paymentId) // Link to the payment record
            };

            // Add recipient information for gift purchases
            if (request.OperationType == MembershipOperationType.GiftPurchase)
            {
                userMembership.RecipientFirstName = request.RecipientFirstName;
                userMembership.RecipientLastName = request.RecipientLastName;
                userMembership.RecipientEmail = request.RecipientEmail;
            }
            
            // Add shipping information if physical card is requested
            if (request.PhysicalCardRequested)
            {
                if (request.OperationType == MembershipOperationType.Renewal && request.Shipping == null)
                {
                    // For renewals, use previous address if not updating
                    var previousMembership = await _context.UserMemberships
                        .FirstOrDefaultAsync(um => um.Id == request.PreviousMembershipId);
                        
                    if (previousMembership != null)
                    {
                        userMembership.ShippingAddress = previousMembership.ShippingAddress;
                        userMembership.ShippingCity = previousMembership.ShippingCity;
                        userMembership.ShippingPostalCode = previousMembership.ShippingPostalCode;
                        userMembership.ShippingCountry = previousMembership.ShippingCountry;
                    }
                }
                else if (request.Shipping != null)
                {
                    // Use new shipping information
                    userMembership.ShippingAddress = request.Shipping.ShippingAddress;
                    userMembership.ShippingCity = request.Shipping.ShippingCity;
                    userMembership.ShippingPostalCode = request.Shipping.ShippingPostalCode;
                    userMembership.ShippingCountry = request.Shipping.ShippingCountry;
                }
            }
            
            // Add the user membership
            _context.UserMemberships.Add(userMembership);
            
            // Update the membership card total members
            membershipCard.TotalMembers += 1;
            
            await _context.SaveChangesAsync();
            
            // Load related entities for the response
            await _context.Entry(userMembership)
                .Reference(um => um.User)
                .LoadAsync();
                
            await _context.Entry(userMembership)
                .Reference(um => um.MembershipCard)
                .LoadAsync();
                
            return MapToResponse(userMembership);
        }

        public async Task<UserMembershipCardResponse> GetUserMembershipCardAsync(int membershipId)
        {
            var userMembership = await _context.UserMemberships
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .ThenInclude(mc => mc.Image)
                .FirstOrDefaultAsync(um => um.Id == membershipId);
                
            if (userMembership == null)
            {
                return null;
            }
            
            // Generate a unique membership number
            string membershipNumber = $"{userMembership.MembershipCard.Year}-{userMembership.Id:D6}";
            
            // Create QR code data (in a real app, this would be encrypted or digitally signed)
            string qrCodeData = $"MID:{userMembership.Id}|UID:{userMembership.UserId}|MCID:{userMembership.MembershipCardId}|DATE:{userMembership.JoinDate:yyyyMMdd}";
            
            var response = new UserMembershipCardResponse
            {
                Id = userMembership.Id,
                MembershipCardName = userMembership.MembershipCard.Name,
                Year = userMembership.MembershipCard.Year,
                UserFullName = !string.IsNullOrEmpty(userMembership.RecipientFirstName) 
                    ? $"{userMembership.RecipientFirstName} {userMembership.RecipientLastName}"
                    : $"{userMembership.User.FirstName} {userMembership.User.LastName}",
                JoinDate = userMembership.JoinDate,
                MembershipNumber = membershipNumber,
                CardImageUrl = userMembership.MembershipCard.Image?.Url,
                IsActive = userMembership.MembershipCard.IsActive,
                ValidUntil = userMembership.MembershipCard.EndDate,
                QRCodeData = qrCodeData
            };
            
            return response;
        }

        public async Task<bool> MarkAsShippedAsync(int membershipId)
        {
            var userMembership = await _context.UserMemberships
                .FirstOrDefaultAsync(um => um.Id == membershipId && um.PhysicalCardRequested && !um.IsShipped);
                
            if (userMembership == null)
            {
                throw new Exception("Membership not found or physical card not requested or already shipped");
            }
            
            userMembership.IsShipped = true;
            userMembership.ShippedDate = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            
            return true;
        }

        protected override UserMembershipResponse MapToResponse(UserMembership entity)
        {
            var response = new UserMembershipResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserFullName = $"{entity.User?.FirstName} {entity.User?.LastName}",
                MembershipCardId = entity.MembershipCardId,
                MembershipName = entity.MembershipCard?.Name,
                Year = entity.MembershipCard?.Year ?? 0,
                JoinDate = entity.JoinDate,
                IsRenewal = entity.IsRenewal,
                PreviousMembershipId = entity.PreviousMembershipId,
                PhysicalCardRequested = entity.PhysicalCardRequested,
                RecipientFullName = !string.IsNullOrEmpty(entity.RecipientFirstName) 
                    ? $"{entity.RecipientFirstName} {entity.RecipientLastName}" 
                    : string.Empty,
                RecipientEmail = entity.RecipientEmail,
                ShippingAddress = entity.ShippingAddress,
                ShippingCity = entity.ShippingCity,
                ShippingPostalCode = entity.ShippingPostalCode,
                ShippingCountry = entity.ShippingCountry,
                IsShipped = entity.IsShipped,
                ShippedDate = entity.ShippedDate,
                PaymentAmount = entity.Payment?.Amount ?? 0,
                IsPaid = entity.IsPaid,
                PaymentDate = entity.PaymentDate
            };
            
            return response;
        }

        private int GetCurrentUserId()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null)
            {
                throw new Exception("No HTTP context available");
            }

            string? authHeader = httpContext.Request.Headers["Authorization"].ToString();
            if (string.IsNullOrEmpty(authHeader))
            {
                throw new Exception("No authorization header found");
            }

            return JwtTokenManager.GetUserIdFromToken(authHeader);
        }
    }
} 