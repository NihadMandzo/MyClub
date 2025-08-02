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

namespace MyClub.Services
{
    public class MatchService : BaseCRUDService<MatchResponse, BaseSearchObject, MatchUpsertRequest, MatchUpsertRequest, Database.Match>, IMatchService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;

        public MatchService(MyClubContext context, IMapper mapper)
            : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
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

        public async Task<List<MatchResponse>> GetUpcomingMatchesAsync(int? clubId = null, int? count = null)
        {
            // Create a simple IQueryable first
            var query = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                .ThenInclude(t => t.StadiumSector)
                .ThenInclude(s => s.StadiumSide)
                .Where(m => m.MatchDate > DateTime.UtcNow).AsQueryable();

            // Apply club filter if needed
            if (clubId.HasValue)
            {
                query = query.Where(m => m.ClubId == clubId.Value);
            }

            // Order the query
            var orderedQuery = query.OrderBy(m => m.MatchDate);

            // Apply limit if needed
            if (count.HasValue)
            {
                query = orderedQuery.Take(count.Value);
            }
            else
            {
                query = orderedQuery;
            }

            var matches = await query.ToListAsync();
            return matches.Select(m => MapToResponse(m)).ToList();
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

        public async Task<UserTicketResponse> PurchaseTicketAsync(TicketPurchaseRequest request)
        {
            //     using var transaction = await _context.Database.BeginTransactionAsync();
            //     try
            //     {
            //         // Get the match ticket
            //         var matchTicket = await _context.MatchTickets
            //             .Include(mt => mt.Match)
            //             .Include(mt => mt.StadiumSector)
            //             .ThenInclude(ss => ss.StadiumSide)
            //             .FirstOrDefaultAsync(mt => mt.Id == request.MatchTicketId);

            //         if (matchTicket == null)
            //             throw new Exception($"Match ticket with ID {request.MatchTicketId} not found");

            //         // Check if the ticket is active
            //         if (!matchTicket.IsActive)
            //             throw new Exception("The selected tickets are not available for purchase");

            //         // Check if there are enough tickets available
            //         if (matchTicket.AvailableQuantity < request.Quantity)
            //             throw new Exception($"Not enough tickets available. Requested: {request.Quantity}, Available: {matchTicket.AvailableQuantity}");

            //         // Get the user
            //         var user = await _context.Users.FindAsync(request.UserId);
            //         if (user == null)
            //             throw new Exception($"User with ID {request.UserId} not found");

            //         // Calculate total price
            //         decimal totalPrice = matchTicket.Price * request.Quantity;

            //         // Create a payment record first
            //         var payment = new Payment
            //         {
            //             Id = Guid.NewGuid(),
            //             Amount = totalPrice,
            //             Method = "Card", // Default method, should be passed from request
            //             Status = "Succeeded", // Assuming payment is successful immediately
            //             CreatedAt = DateTime.UtcNow,
            //             CompletedAt = DateTime.UtcNow
            //         };

            //         _context.Payments.Add(payment);
            //         await _context.SaveChangesAsync();

            //         // Generate QR code data
            //         string qrCodeData = GenerateQRCodeData(request.UserId, matchTicket.Match.Id, matchTicket.StadiumSectorId, request.Quantity);

            //         // Create the user ticket
            //         var userTicket = new UserTicket
            //         {
            //             UserId = request.UserId,
            //             MatchTicketId = request.MatchTicketId,
            //             Quantity = request.Quantity,
            //             TotalPrice = totalPrice,
            //             PurchaseDate = DateTime.UtcNow,
            //             QRCode = qrCodeData,
            //             Status = "Valid",
            //             PaymentId = payment.Id // Link to the payment record
            //         };

            //         // Update available tickets
            //         matchTicket.AvailableQuantity -= request.Quantity;

            //         // Save changes
            //         _context.UserTickets.Add(userTicket);
            //         _context.MatchTickets.Update(matchTicket);
            //         await _context.SaveChangesAsync();

            //         await transaction.CommitAsync();

            //         // Return the response
            //         return new UserTicketResponse
            //         {
            //             Id = userTicket.Id,
            //             Quantity = userTicket.Quantity,
            //             TotalPrice = userTicket.TotalPrice,
            //             PurchaseDate = userTicket.PurchaseDate,
            //             QRCodeData = qrCodeData,
            //             MatchId = matchTicket.Match.Id,
            //             OpponentName = matchTicket.Match.OpponentName,
            //             MatchDate = matchTicket.Match.MatchDate,
            //             Location = matchTicket.Match.Location,
            //             SectorCode = matchTicket.StadiumSector.Code,
            //             StadiumSide = matchTicket.StadiumSector.StadiumSide.Name
            //         };
            //     }
            //     catch (Exception)
            //     {
            //         await transaction.RollbackAsync();
            //         throw;
            //     }

            return null;
        }

        public async Task<PagedResult<UserTicketResponse>> GetUserTicketsAsync(int userId, bool upcomingOnly = false)
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
                Quantity = ut.Quantity,
                TotalPrice = ut.TotalPrice,
                PurchaseDate = ut.PurchaseDate,
                QRCodeData = ut.QRCode,
                MatchId = ut.MatchTicket.Match.Id,
                OpponentName = ut.MatchTicket.Match.OpponentName,
                MatchDate = ut.MatchTicket.Match.MatchDate,
                Location = ut.MatchTicket.Match.Location,
                SectorCode = ut.MatchTicket.StadiumSector.Code,
                StadiumSide = ut.MatchTicket.StadiumSector.StadiumSide.Name
            }).ToList();

            // Create the paged result with proper pagination metadata
            return new PagedResult<UserTicketResponse>
            {
                Data = response,
                TotalCount = totalCount,
                CurrentPage = 0,
                PageSize = totalCount > 0 ? totalCount : 10
            };
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

                if (userTicket == null)
                    return new QRValidationResponse { IsValid = false, Message = "Ticket not found" };

                // Check if the ticket has already been used
                if (userTicket.Status != "Valid")
                    return new QRValidationResponse { IsValid = false, Message = $"Ticket is {userTicket.Status}" };

                // Check if the match is in the future
                if (userTicket.MatchTicket.Match.MatchDate < DateTime.UtcNow)
                    return new QRValidationResponse { IsValid = false, Message = "Match has already taken place" };

                // Mark the ticket as used
                userTicket.Status = "Used";
                await _context.SaveChangesAsync();

                // Return success
                return new QRValidationResponse
                {
                    IsValid = true,
                    Message = "Ticket is valid",
                    TicketDetails = new UserTicketDetails
                    {
                        TicketId = userTicket.Id,
                        Username = userTicket.User.Username,
                        Quantity = userTicket.Quantity,
                        MatchInfo = $"{userTicket.MatchTicket.Match.OpponentName} on {userTicket.MatchTicket.Match.MatchDate:g}",
                        SectorInfo = $"{userTicket.MatchTicket.StadiumSector.StadiumSide.Name} - {userTicket.MatchTicket.StadiumSector.Code}",
                        PurchaseDate = userTicket.PurchaseDate
                    }
                };
            }
            catch (Exception ex)
            {
                return new QRValidationResponse { IsValid = false, Message = $"Error validating QR code: {ex.Message}" };
            }
        }

        public async Task<PagedResult<MatchResponse>> GetAvailableMatchesAsync(BaseSearchObject search)
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
                    m.Status.ToLower().Contains(searchTerm) ||
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
            entity.Status = request.Status;
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
            entity.Status = request.Status;
            entity.Description = request.Description;
            entity.ClubId = request.ClubId;

            return entity;
        }

        private MatchResponse MapToResponse(Database.Match entity)
        {
            var response = _mapper.Map<MatchResponse>(entity);

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
                        SideName = t.StadiumSector.StadiumSide.Name
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
                    m.Status.ToLower().Contains(searchTerm) ||
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
            return null;
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


                    if(ticketRequest.ReleasedQuantity < 0 || ticketRequest.ReleasedQuantity > 100 || ticketRequest.Price < 0)
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

                        if(matchTicket.ReleasedQuantity + ticketRequest.ReleasedQuantity > 100)
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
    }
}