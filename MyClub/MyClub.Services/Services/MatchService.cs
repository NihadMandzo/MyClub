using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MapsterMapper;
using System;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
using System.Threading.Tasks;
using MyClub.Model;
using MyClub.Services.Helpers;
using Microsoft.AspNetCore.Http;

namespace MyClub.Services
{
    public class MatchService : BaseCRUDService<MatchResponse, BaseSearchObject, MatchUpsertRequest, MatchUpsertRequest, Database.Match>, IMatchService
    {
        private readonly MyClubContext _context;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IPaymentService _paymentService;

        public MatchService(MyClubContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IPaymentService paymentService)
            : base(context, mapper)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
            _paymentService = paymentService;
        }

        public override async Task<PagedResult<MatchResponse>> GetAsync(BaseSearchObject search)
        {
            var query = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .AsQueryable();

            // Apply filters based on BaseSearchObject
            query = ApplyFilter(query, search);

            // Include tickets
            query = query.Include(m => m.Tickets)
                .ThenInclude(t => t.StadiumSector)
                .ThenInclude(s => s.StadiumSide);

            // Order by match date
            query = query.OrderBy(m => m.MatchDate);

            // Get total count if requested
            int totalCount = 0;
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

            // Create the paged result
            return new PagedResult<MatchResponse>
            {
                Data = list.Select(x => MapToResponse(x)).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }
        public override async Task<MatchResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                .ThenInclude(t => t.StadiumSector)
                .ThenInclude(s => s.StadiumSide)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }
        public override async Task<MatchResponse> CreateAsync(MatchUpsertRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = MapInsertToEntity(new Database.Match(), request);
                await BeforeInsert(entity, request);
                _context.Matches.Add(entity);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return await GetByIdAsync(entity.Id);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public override async Task<MatchResponse> UpdateAsync(int id, MatchUpsertRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.Matches
                    .Include(m => m.Tickets)
                    .FirstOrDefaultAsync(m => m.Id == id);

                if (entity == null)
                    throw new Exception($"Match with ID {id} not found");

                await BeforeUpdate(entity, request);
                MapUpdateToEntity(entity, request);
                _context.Matches.Update(entity);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public async Task<PaymentResponse> PurchaseTicketAsync(TicketPurchaseRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Get the match ticket
                var matchTicket = await _context.MatchTickets
                    .Include(mt => mt.Match)
                    .Include(mt => mt.StadiumSector)
                    .ThenInclude(ss => ss.StadiumSide)
                    .FirstOrDefaultAsync(mt => mt.Id == request.MatchTicketId);

                if (matchTicket == null)
                    throw new UserException($"Match ticket with ID {request.MatchTicketId} not found");

                // Check if the ticket is available for purchase
                if (matchTicket.AvailableQuantity <= 0)
                    throw new UserException("No tickets available for this match");

                // Check if the match is in the future
                if (matchTicket.Match.MatchDate <= DateTime.UtcNow)
                    throw new UserException("Cannot purchase tickets for past matches");

                string? authHeader = _httpContextAccessor.HttpContext?.Request.Headers["Authorization"];
                if (string.IsNullOrEmpty(authHeader))
                    throw new UserException("Authorization header is required");

                var userId = JwtTokenManager.GetUserIdFromToken(authHeader);

                // Create Stripe payment intent using PaymentService
                var paymentResponse = await _paymentService.CreateStripePaymentAsync(request);

                // Create a payment record with pending status
                var payment = new Payment
                {
                    Amount = request.Amount,
                    Method = "Card",
                    Status = "Pending", // Initially pending until confirmed
                    CreatedAt = DateTime.UtcNow,
                    TransactionId = paymentResponse.transactionId
                };

                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();

                // Generate QR code data but don't create user ticket yet - wait for payment confirmation
                string qrCodeData = GenerateQRCodeData(userId, matchTicket.Match.Id, matchTicket.StadiumSectorId, 1);

                // Create a user ticket record but mark it as not valid until payment is confirmed
                var userTicket = new UserTicket
                {
                    UserId = userId,
                    MatchTicketId = request.MatchTicketId,
                    TotalPrice = request.Amount,
                    PurchaseDate = DateTime.UtcNow,
                    IsValid = false, // Will be set to true when payment is confirmed
                    QRCode = qrCodeData,
                    PaymentId = payment.Id
                };

                _context.UserTickets.Add(userTicket);

                // Temporarily reserve the ticket by reducing available quantity
                matchTicket.AvailableQuantity -= 1;
                _context.MatchTickets.Update(matchTicket);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                // Return the user ticket response with payment information
                return new PaymentResponse
                {
                    transactionId = paymentResponse.transactionId,
                    clientSecret = paymentResponse.clientSecret
                };
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public async Task<List<UserTicketResponse>> GetUserTicketsAsync(int userId, bool upcomingOnly = false)
        {
            var query = _context.UserTickets
                .AsNoTracking()
                .Include(ut => ut.User)
                .Include(ut => ut.MatchTicket)
                .ThenInclude(mt => mt.Match)
                .Include(ut => ut.MatchTicket.StadiumSector)
                .ThenInclude(ss => ss.StadiumSide)
                .Where(ut => ut.UserId == userId)
                .AsQueryable();

            // Filter for upcoming matches only if requested
            if (upcomingOnly)
            {
                query = query.Where(ut => ut.MatchTicket.Match.MatchDate > DateTime.UtcNow);
            }

            // Order by match date (upcoming first, then past)
            query = query.OrderBy(ut => ut.MatchTicket.Match.MatchDate < DateTime.UtcNow ? 1 : 0)
                .ThenBy(ut => ut.MatchTicket.Match.MatchDate);

            // Get total count
            int totalCount = await query.CountAsync();

            // Get all tickets - no pagination for user tickets as they're typically few
            var list = await query.ToListAsync();

            // Map to response
            var response = list.Select(ut => new UserTicketResponse
            {
                Id = ut.Id,
                TotalPrice = ut.TotalPrice,
                PurchaseDate = ut.PurchaseDate,
                QRCodeData = ut.QRCode,
                IsValid = ut.IsValid,
                MatchId = ut.MatchTicket.Match.Id,
                OpponentName = ut.MatchTicket.Match.OpponentName,
                MatchDate = ut.MatchTicket.Match.MatchDate,
                Location = ut.MatchTicket.Match.Location,
                SectorCode = ut.MatchTicket.StadiumSector.Code,
                StadiumSide = ut.MatchTicket.StadiumSector.StadiumSide.Name
            }).ToList();

            // Create the paged result with proper pagination metadata
            return response;
        }
        public async Task<QRValidationResponse> ValidateQRCodeAsync(QRValidationRequest request)
        {
            try
            {
                // Find user ticket by QR code
                var userTicket = await _context.UserTickets
                    .Include(ut => ut.User)
                    .Include(ut => ut.MatchTicket)
                    .ThenInclude(mt => mt.Match)
                    .Include(ut => ut.MatchTicket.StadiumSector)
                    .ThenInclude(ss => ss.StadiumSide)
                    .FirstOrDefaultAsync(ut => ut.QRCode == request.QRCodeData);

                if (userTicket == null || !userTicket.IsValid)
                    return new QRValidationResponse { IsValid = false, Message = "Karta nije validna" }; 

                // Check if the match is in the future
                if (userTicket.MatchTicket.Match.MatchDate < (DateTime.UtcNow + TimeSpan.FromMinutes(10)))
                    return new QRValidationResponse { IsValid = false, Message = "Utakmica je već odigrana" };

                // Mark the ticket as used
                userTicket.IsValid = false;
                await _context.SaveChangesAsync();

                // Return success
                return new QRValidationResponse
                {
                    IsValid = true,
                    Message = "Karta je validna",
                };
            }
            catch (Exception ex)
            {
                return new QRValidationResponse { IsValid = false, Message = $"Error validating QR code: {ex.Message}" };
            }
        }
        public async Task<PagedResult<MatchResponse>> GetUpcomingMatchesAsync(BaseSearchObject search)
        {
            // Create query for matches with available tickets
            var now = DateTime.UtcNow;

            // Start with getting all matches and include necessary related entities
            var query = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                    .ThenInclude(t => t.StadiumSector)
                    .ThenInclude(s => s.StadiumSide)
                .Where(m => m.MatchDate > now) // Only upcoming matches
                .AsQueryable();

            // Apply any text search
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(m =>
                    m.OpponentName.ToLower().Contains(searchTerm) ||
                    m.Location.ToLower().Contains(searchTerm) ||
                    m.Club.Name.ToLower().Contains(searchTerm)
                );
            }

            // Order by match date
            query = query.OrderBy(m => m.MatchDate);

            // Get total count
            int totalCount = await query.CountAsync();

            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;

            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();

            Console.WriteLine($"Available matches query returned {list.Count} matches");

            // Map to response
            return new PagedResult<MatchResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }
        protected override async Task BeforeInsert(Database.Match entity, MatchUpsertRequest request)
        {
            await ValidateAsync(request);
        }
        protected override async Task BeforeUpdate(Database.Match entity, MatchUpsertRequest request)
        {
            await ValidateAsync(request);
        }
        protected override async Task BeforeDelete(Database.Match entity)
        {
            // Check if there are any user tickets for this match
            var hasUserTickets = await _context.UserTickets
                .AnyAsync(ut => ut.MatchTicket.MatchId == entity.Id);

            if (hasUserTickets)
                throw new Exception("Cannot delete match as tickets have already been purchased");

            // Delete match tickets
            var tickets = await _context.MatchTickets
                .Where(t => t.MatchId == entity.Id)
                .ToListAsync();

            _context.MatchTickets.RemoveRange(tickets);
            await _context.SaveChangesAsync();
        }
        private async Task<bool> ValidateAsync(MatchUpsertRequest request)
        {
            // Validate club exists
            var clubExists = await _context.Clubs.AnyAsync(c => c.Id == request.ClubId);
            if (!clubExists)
                throw new Exception($"Club with ID {request.ClubId} does not exist");

            return true;
        }
        protected override Database.Match MapInsertToEntity(Database.Match entity, MatchUpsertRequest request)
        {
            entity.MatchDate = request.MatchDate;
            entity.OpponentName = request.OpponentName;
            entity.Location = request.Location;
            entity.Description = request.Description;
            entity.ClubId = request.ClubId;
            entity.Tickets = new List<MatchTicket>();

            return entity;
        }
        protected override Database.Match MapUpdateToEntity(Database.Match entity, MatchUpsertRequest request)
        {
            entity.MatchDate = request.MatchDate;
            entity.OpponentName = request.OpponentName;
            entity.Location = request.Location;
            entity.Description = request.Description;
            entity.ClubId = request.ClubId;

            return entity;
        }
        protected override MatchResponse MapToResponse(Database.Match entity)
        {
            var response = _mapper.Map<MatchResponse>(entity);
            response.Status = entity.MatchDate > DateTime.UtcNow ? "Zakazana" : "Završena";
            // Add club name
            response.ClubName = entity.Club?.Name;

            // Map tickets
            if (entity.Tickets != null)
            {
                response.Tickets = entity.Tickets.Select(t => new MatchTicketResponse
                {
                    Id = t.Id,
                    MatchId = t.MatchId,
                    ReleasedQuantity = t.ReleasedQuantity,
                    Price = t.Price,
                    StadiumSector = new StadiumSectorResponse
                    {
                        Id = t.StadiumSectorId,
                        Capacity = t.StadiumSector.Capacity,
                        Code = t.StadiumSector.Code,
                        StadiumSide = new StadiumSideResponse
                        {
                            Id = t.StadiumSector.StadiumSideId,
                            Name = t.StadiumSector.StadiumSide.Name
                        }
                    },
                    AvailableQuantity = t.AvailableQuantity,
                    UsedQuantity = t.UsedQuantity
                }).ToList();
            }
            // Map match result
            response.Result = new MatchResultResponse
            {
                HomeGoals = entity.HomeGoals,
                AwayGoals = entity.AwayGoals
            };

            return response;
        }
        private string GenerateQRCodeData(int userId, int matchId, int sectorId, int quantity)
        {
            // Create a unique ticket identifier with important details
            string ticketData = $"{userId}|{matchId}|{sectorId}|{quantity}|{DateTime.UtcNow.Ticks}";

            // Generate a hash for verification and make it part of the QR code
            string hash = GenerateHash(ticketData);

            return $"{ticketData}|{hash}";
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
        protected override IQueryable<Match> ApplyFilter(IQueryable<Match> query, BaseSearchObject search)
        {
            // Apply text search filter
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(m =>
                    m.OpponentName.ToLower().Contains(searchTerm) ||
                    m.Location.ToLower().Contains(searchTerm) ||
                    m.Club.Name.ToLower().Contains(searchTerm)
                );
            }

            // Make sure we're returning matches
            Console.WriteLine($"Query will return {query.Count()} matches");

            return query;
        }
        public async Task<UserTicketResponse> ConfirmPurchaseTicketAsync(string transactionId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Confirm payment with PaymentService
                var paymentConfirmed = await _paymentService.ConfirmStripePayment(transactionId);

                if (!paymentConfirmed)
                    throw new UserException("Payment confirmation failed");

                // Find the user ticket associated with this transaction
                var payment = await _context.Payments
                    .FirstOrDefaultAsync(p => p.TransactionId == transactionId);

                if (payment == null)
                    throw new UserException($"Payment with transaction ID {transactionId} not found");

                var userTicket = await _context.UserTickets
                    .Include(ut => ut.MatchTicket)
                    .ThenInclude(mt => mt.Match)
                    .Include(ut => ut.MatchTicket.StadiumSector)
                    .ThenInclude(ss => ss.StadiumSide)
                    .FirstOrDefaultAsync(ut => ut.PaymentId == payment.Id);

                if (userTicket == null)
                    throw new UserException("User ticket not found for this payment");

                // Mark the ticket as valid now that payment is confirmed
                userTicket.IsValid = true;
                _context.UserTickets.Update(userTicket);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Return the confirmed ticket
                return new UserTicketResponse
                {
                    Id = userTicket.Id,
                    TotalPrice = userTicket.TotalPrice,
                    PurchaseDate = userTicket.PurchaseDate,
                    QRCodeData = userTicket.QRCode,
                    IsValid = userTicket.IsValid,
                    MatchId = userTicket.MatchTicket.Match.Id,
                    OpponentName = userTicket.MatchTicket.Match.OpponentName,
                    MatchDate = userTicket.MatchTicket.Match.MatchDate,
                    Location = userTicket.MatchTicket.Match.Location,
                    SectorCode = userTicket.MatchTicket.StadiumSector.Code,
                    StadiumSide = userTicket.MatchTicket.StadiumSector.StadiumSide.Name
                };
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public async Task<MatchResponse> UpdateMatchResultAsync(int matchId, MatchResultRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var match = await _context.Matches.FindAsync(matchId);
                if (match == null)
                    throw new Exception($"Match with ID {matchId} not found");

                match.HomeGoals = request.HomeGoals;
                match.AwayGoals = request.AwayGoals;

                _context.Matches.Update(match);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return MapToResponse(match);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public override async Task<bool> DeleteAsync(int id)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.Matches
                    .Include(m => m.Tickets)
                    .FirstOrDefaultAsync(m => m.Id == id);

                if (entity == null)
                    throw new Exception($"Match with ID {id} not found");

                await BeforeDelete(entity);
                _context.Matches.Remove(entity);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return true;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public async Task<MatchResponse> CreateOrUpdateMatchTicketAsync(int matchId, List<MatchTicketUpsertRequest> request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var matchTickets = new List<Database.MatchTicket>();
                foreach (var ticketRequest in request)
                {
                    var matchTicket = await _context.MatchTickets
                        .FirstOrDefaultAsync(mt => mt.MatchId == matchId && mt.StadiumSectorId == ticketRequest.StadiumSectorId);


                    if (ticketRequest.ReleasedQuantity < 0 || ticketRequest.ReleasedQuantity > 100 || ticketRequest.Price < 0)
                    {
                        throw new UserException("Released quantity cannot be negative and price cannot be negative");
                    }

                    // Validate ticket request
                    if (ticketRequest.ReleasedQuantity > 100)
                    {
                        throw new UserException("Released quantity cannot exceed 100", 400);
                    }
                    if (matchTicket == null)
                    {
                        // Create new ticket
                        matchTicket = new Database.MatchTicket
                        {
                            MatchId = matchId,
                            ReleasedQuantity = ticketRequest.ReleasedQuantity,
                            Price = ticketRequest.Price,
                            StadiumSectorId = ticketRequest.StadiumSectorId,
                            AvailableQuantity = ticketRequest.ReleasedQuantity // Initially all released tickets are available
                        };
                        _context.MatchTickets.Add(matchTicket);
                    }
                    else
                    {
                        // Update existing ticket

                        if (matchTicket.ReleasedQuantity + ticketRequest.ReleasedQuantity > 100)
                        {
                            throw new UserException("Total released quantity cannot exceed 100", 400);
                        }
                        matchTicket.ReleasedQuantity += ticketRequest.ReleasedQuantity;
                        matchTicket.AvailableQuantity += ticketRequest.ReleasedQuantity; // Reset available quantity
                        matchTicket.Price = ticketRequest.Price;
                    }

                    matchTickets.Add(matchTicket);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Return the complete match response with all tickets
                return await GetByIdAsync(matchId);
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        public async Task<PagedResult<MatchResponse>> GetPastMatchesAsync(BaseSearchObject search)
        {
            // Create query for matches with available tickets
            var now = DateTime.UtcNow;

            // Start with getting all matches and include necessary related entities
            var query = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                    .ThenInclude(t => t.StadiumSector)
                    .ThenInclude(s => s.StadiumSide)
                .Where(m => m.MatchDate <= now) // Only past matches
                .AsQueryable();

            // Apply any text search
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(m =>
                    m.OpponentName.ToLower().Contains(searchTerm) ||
                    m.Location.ToLower().Contains(searchTerm) ||
                    m.Club.Name.ToLower().Contains(searchTerm)
                );
            }

            // Order by match date
            query = query.OrderBy(m => m.MatchDate);

            // Get total count
            int totalCount = await query.CountAsync();

            // Apply pagination
            int pageSize = search.PageSize ?? 10;
            int currentPage = search.Page ?? 0;

            if (!search.RetrieveAll)
            {
                query = query.Skip(currentPage * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();

            Console.WriteLine($"Available matches query returned {list.Count} matches");

            // Map to response
            return new PagedResult<MatchResponse>
            {
                Data = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                CurrentPage = currentPage,
                PageSize = pageSize
            };
        }
    }
}