using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
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
    public class UserMembershipService : BaseService<UserMembershipResponse, UserMembershipSearchObject, UserMembership>, IUserMembershipService
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

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.User.Username.Contains(search.FTS) || x.User.FirstName.Contains(search.FTS) || x.User.LastName.Contains(search.FTS));
            }

            return query.OrderByDescending(x => x.JoinDate);
        }

        public override async Task<PagedResult<UserMembershipResponse>> GetAsync(UserMembershipSearchObject search)
        {
            // Suppress nullable warnings for EF navigation includes; EF safely handles null navigations in Include chains
            #pragma warning disable CS8602
            var query = _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .Include(um => um.Payment)
                .Include(um => um.ShippingDetails)
                    .ThenInclude(sd => sd.City!)
                        .ThenInclude(c => c.Country)
                .OrderByDescending(x => x.JoinDate)
                .AsQueryable();
            #pragma warning restore CS8602
                
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
            #pragma warning disable CS8602
            var entity = await _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .Include(um => um.Payment)
                .Include(um => um.ShippingDetails)
                    .ThenInclude(sd => sd.City!)
                        .ThenInclude(c => c.Country)
                .FirstOrDefaultAsync(um => um.Id == id);
            #pragma warning restore CS8602

            if (entity == null)
            {
                return null;
            }

            return MapToResponse(entity);
        }

        public async Task<PagedResult<UserMembershipCardResponse>> GetUserMembershipsAsync(int userId)
        {
            var query = _context.UserMemberships
                .AsNoTracking()
                .Include(um => um.User)
                .Include(um => um.MembershipCard).ThenInclude(x => x.Image)
                .Where(um => um.UserId == userId && um.IsPaid)
                .OrderByDescending(um => um.MembershipCard.Year)
                .ThenByDescending(um => um.JoinDate);

            
                
            var totalCount = await query.CountAsync();
            var memberships = await query.ToListAsync();

            return new PagedResult<UserMembershipCardResponse>
            {
                Data = memberships.Select(MapToCardResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = 0,
                PageSize = totalCount > 0 ? totalCount : 10
            };
        }

        private UserMembershipCardResponse MapToCardResponse(UserMembership membership)
        {
            // Generate QR code data similar to the MatchService pattern
            string qrCodeData = GenerateMembershipQRCodeData(membership.UserId, membership.Id, membership.MembershipCardId);

            return new UserMembershipCardResponse
            {
                Id = membership.Id,
                UserFullName = !string.IsNullOrEmpty(membership.RecipientFirstName) 
                    ? $"{membership.RecipientFirstName} {membership.RecipientLastName}"
                    : $"{membership.User?.FirstName} {membership.User?.LastName}",
                MembershipCardName = membership.MembershipCard?.Name ?? string.Empty,
                Year = membership.MembershipCard?.Year ?? 0,
                JoinDate = membership.JoinDate,
                MembershipNumber = $"{membership.MembershipCard?.Year}-{membership.Id:D6}",
                CardImageUrl = membership.MembershipCard?.Image?.Url ?? string.Empty,
                IsActive = membership.MembershipCard?.IsActive ?? false,
                ValidUntil = membership.MembershipCard?.EndDate ?? DateTime.MinValue,
                QRCodeData = qrCodeData
            };
        }

        public async Task<PaymentResponse> PurchaseMembershipAsync(MembershipPurchaseRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Validate membership card exists and is active
                var membershipCard = await _context.MembershipCards
                    .FirstOrDefaultAsync(mc => mc.Id == request.MembershipCardId);

                if (membershipCard == null)
                {
                    throw new ArgumentException("Membership card not found.");
                }

                if (!membershipCard.IsActive)
                {
                    throw new InvalidOperationException("Membership card is not active.");
                }

                // Validate amount
                if (Math.Abs(request.Amount - membershipCard.Price) > 0.1m)
                {
                    throw new ArgumentException("Invalid amount for membership card.");
                }

                // Get current user ID
                var authHeader = _httpContextAccessor.HttpContext?.Request.Headers["Authorization"].FirstOrDefault();
                if (string.IsNullOrEmpty(authHeader))
                {
                    throw new UnauthorizedAccessException("Authentication required.");
                }

                var currentUserId = GetCurrentUserId();

                // Check if user already has membership for this year (only if not a gift purchase)
                bool isGiftPurchase = !string.IsNullOrEmpty(request.RecipientFirstName) && 
                                     !string.IsNullOrEmpty(request.RecipientLastName);

                if (!isGiftPurchase)
                {
                    var existingMembership = await _context.UserMemberships
                        .Include(um => um.MembershipCard)
                        .FirstOrDefaultAsync(um => um.UserId == currentUserId && 
                                           um.MembershipCard.Year == membershipCard.Year);

                    if (existingMembership != null)
                    {
                        throw new InvalidOperationException($"User already has membership for year {membershipCard.Year}.");
                    }
                }

                // Create payment request
                PaymentResponse paymentResponse;
                if (request.Type == "Stripe")
                {
                    paymentResponse = await _paymentService.CreateStripePaymentAsync(request);
                }
                else if (request.Type == "PayPal")
                {
                    paymentResponse = await _paymentService.CreatePayPalPaymentAsync(request);
                }
                else
                {
                    throw new ArgumentException("Invalid payment type. Use 'Stripe' or 'PayPal'.");
                }

                // Create payment record in database with pending status
                var payment = new Payment
                {
                    Amount = request.Amount,
                    Method = request.Type,
                    Status = "Pending", // Initially pending until confirmed
                    CreatedAt = DateTime.UtcNow,
                    TransactionId = paymentResponse.transactionId ?? string.Empty
                };

                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();

                // Create shipping details if physical card is requested
                ShippingDetails? shippingDetails = null;
                if (request.PhysicalCardRequested)
                {
                    if (request.Shipping == null)
                    {
                        throw new ArgumentException("Shipping details are required for physical card delivery.");
                    }

                    shippingDetails = new ShippingDetails
                    {
                        ShippingAddress = request.Shipping.ShippingAddress,
                        CityId = request.Shipping.CityId
                    };

                    _context.ShippingDetails.Add(shippingDetails);
                    await _context.SaveChangesAsync();
                }

                // Create user membership record (initially unpaid)
                var userMembership = new UserMembership
                {
                    UserId = currentUserId,
                    MembershipCardId = request.MembershipCardId,
                    PaymentId = payment.Id, // Use the actual payment ID
                    JoinDate = DateTime.UtcNow,
                    RecipientFirstName = request.RecipientFirstName ?? string.Empty,
                    RecipientLastName = request.RecipientLastName ?? string.Empty,
                    PhysicalCardRequested = request.PhysicalCardRequested,
                    ShippingDetailsId = shippingDetails?.Id,
                    IsShipped = false,
                    IsPaid = false
                };

                _context.UserMemberships.Add(userMembership);
                await _context.SaveChangesAsync();

                // Store the membership ID and transaction ID for later confirmation
                // This could be stored in a temporary table or in memory cache
                // For now, we'll assume the payment service handles this mapping


                await transaction.CommitAsync();
                return paymentResponse;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<UserMembershipCardResponse?> GetUserMembershipCardAsync(int membershipId)
        {
            // Try a more explicit query approach
            var userMembership = await _context.UserMemberships
                .Include(um => um.User)
                .Include(um => um.MembershipCard)
                .FirstOrDefaultAsync(um => um.Id == membershipId);
                
            if (userMembership == null)
            {
                return null;
            }
            
            // Explicitly load the image if it's not already loaded
            if (userMembership.MembershipCard != null && userMembership.MembershipCard.ImageId.HasValue)
            {
                var imageAsset = await _context.Assets
                    .FirstOrDefaultAsync(a => a.Id == userMembership.MembershipCard.ImageId.Value);
                if (imageAsset != null)
                {
                    userMembership.MembershipCard.Image = imageAsset;
                }
            }
            
            // Debug information - log what we actually got from the database
            Console.WriteLine($"UserMembership ID: {userMembership.Id}");
            Console.WriteLine($"MembershipCard ID: {userMembership.MembershipCardId}");
            Console.WriteLine($"MembershipCard is null: {userMembership.MembershipCard == null}");
            if (userMembership.MembershipCard != null)
            {
                Console.WriteLine($"MembershipCard ImageId: {userMembership.MembershipCard.ImageId}");
                Console.WriteLine($"MembershipCard Image is null: {userMembership.MembershipCard.Image == null}");
                if (userMembership.MembershipCard.Image != null)
                {
                    Console.WriteLine($"Image URL: '{userMembership.MembershipCard.Image.Url}'");
                }
            }
            
            // Generate a unique membership number
            string membershipNumber = $"{userMembership.MembershipCard?.Year}-{userMembership.Id:D6}";
            
            // Generate QR code data using the same method as MapToCardResponse
            string qrCodeData = GenerateMembershipQRCodeData(userMembership.UserId, userMembership.Id, userMembership.MembershipCardId);
            
            var response = new UserMembershipCardResponse
            {
                Id = userMembership.Id,
                MembershipCardName = userMembership.MembershipCard?.Name ?? string.Empty,
                Year = userMembership.MembershipCard?.Year ?? 0,
                UserFullName = !string.IsNullOrEmpty(userMembership.RecipientFirstName) 
                    ? $"{userMembership.RecipientFirstName} {userMembership.RecipientLastName}"
                    : $"{userMembership.User?.FirstName} {userMembership.User?.LastName}",
                JoinDate = userMembership.JoinDate,
                MembershipNumber = membershipNumber,
                CardImageUrl = userMembership.MembershipCard?.Image?.Url ?? string.Empty,
                IsActive = userMembership.MembershipCard?.IsActive ?? false,
                ValidUntil = userMembership.MembershipCard?.EndDate ?? DateTime.MinValue,
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
                MembershipName = entity.MembershipCard?.Name ?? string.Empty,
                Year = entity.MembershipCard?.Year ?? 0,
                JoinDate = entity.JoinDate,
                PhysicalCardRequested = entity.PhysicalCardRequested,
                RecipientFullName = !string.IsNullOrEmpty(entity.RecipientFirstName) 
                    ? $"{entity.RecipientFirstName} {entity.RecipientLastName}" 
                    : string.Empty,
                RecipientEmail = entity.User?.Email ?? string.Empty,
                ShippingAddress = entity.ShippingDetails?.ShippingAddress ?? string.Empty,
                ShippingCity = entity.ShippingDetails?.City != null ? new CityResponse
                {
                    Id = entity.ShippingDetails.City.Id,
                    Name = entity.ShippingDetails.City.Name,
                    PostalCode = entity.ShippingDetails.City.PostalCode,
                    Country = entity.ShippingDetails.City.Country != null ? new CountryResponse
                    {
                        Id = entity.ShippingDetails.City.Country.Id,
                        Name = entity.ShippingDetails.City.Country.Name,
                        Code = entity.ShippingDetails.City.Country.Code
                    } : null
                } : null,
                IsShipped = entity.IsShipped,
                ShippedDate = entity.ShippedDate,
                // Ensure non-null, non-zero when paid; fallback to card price if payment record isn't linked
                PaymentAmount = entity.Payment?.Amount 
                                ?? (entity.IsPaid ? (entity.MembershipCard?.Price ?? 0) : 0),
                PaymentMethod = entity.Payment?.Method ?? (entity.IsPaid ? "Unknown" : string.Empty),
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

        public async Task<UserMembershipCardResponse> ConfirmPurchaseMembershipAsync(string transactionId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Find the payment associated with this transaction first
                var payment = await _context.Payments
                    .FirstOrDefaultAsync(p => p.TransactionId == transactionId);

                if (payment == null)
                    throw new InvalidOperationException($"Payment with transaction ID {transactionId} not found");

                // Confirm payment based on method
                bool paymentConfirmed = false;
                if (payment.Method == "Stripe")
                {
                    paymentConfirmed = await _paymentService.ConfirmStripePayment(transactionId);
                }
                else if (payment.Method == "PayPal")
                {
                    paymentConfirmed = true;
                }

                if (!paymentConfirmed)
                    throw new InvalidOperationException("Payment confirmation failed");

                payment.CompletedAt = DateTime.UtcNow;

                // Find the user membership associated with this payment
                var userMembership = await _context.UserMemberships
                    .Include(um => um.User)
                    .Include(um => um.MembershipCard)
                    .ThenInclude(mc => mc.Image)
                    .FirstOrDefaultAsync(um => um.PaymentId == payment.Id);

                if (userMembership == null)
                    throw new InvalidOperationException("User membership not found for this payment");

                // Mark the membership as paid now that payment is confirmed
                userMembership.IsPaid = true;
                userMembership.PaymentDate = DateTime.UtcNow;
                userMembership.PaymentId = payment.Id;

                _context.UserMemberships.Update(userMembership);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Return the confirmed membership card
                return MapToCardResponse(userMembership);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        private string GenerateMembershipQRCodeData(int userId, int membershipId, int membershipCardId)
        {
            // Create a unique membership identifier with important details
            string membershipData = $"{userId}|{membershipId}|{membershipCardId}|{DateTime.UtcNow.Ticks}";

            // Generate a hash for verification and make it part of the QR code
            string hash = GenerateHash(membershipData);

            return $"{membershipData}|{hash}";
        }

        private string GenerateHash(string input)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = Encoding.UTF8.GetBytes(input);
                byte[] hashBytes = sha256.ComputeHash(bytes);

                // Convert to short string representation
                return Convert.ToBase64String(hashBytes).Substring(0, 16);
            }
        }

    }
} 