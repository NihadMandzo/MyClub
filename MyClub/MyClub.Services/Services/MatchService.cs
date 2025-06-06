using Microsoft.EntityFrameworkCore;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using MapsterMapper;
using System;

namespace MyClub.Services
{
    public class MatchService : BaseCRUDService<MatchResponse, MatchSearchObject, MatchUpsertRequest, MatchUpsertRequest, Database.Match>, IMatchService
    {
        private readonly MyClubContext _context;

        public MatchService(MyClubContext context, IMapper mapper) 
            : base(context, mapper)
        {
            _context = context;
        }

        public override async Task<PagedResult<MatchResponse>> GetAsync(MatchSearchObject search)
        {
            var query = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .AsQueryable();

            // Apply filters
            query = ApplyFilter(query, search);

            // Include tickets if requested
            if (search.IncludeTickets == true)
            {
                query = query.Include(m => m.Tickets)
                    .ThenInclude(t => t.StadiumSector);
            }

            int totalCount = 0;
            
            // Get total count if requested
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
                .FirstOrDefaultAsync(m => m.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public async Task<List<MatchResponse>> GetUpcomingMatchesAsync(int? clubId = null, int? count = null)
        {
            // Create a simple IQueryable first
            IQueryable<Database.Match> baseQuery = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                .ThenInclude(t => t.StadiumSector)
                .Where(m => m.MatchDate > DateTime.UtcNow);
                
            // Apply club filter if needed
            if (clubId.HasValue)
            {
                baseQuery = baseQuery.Where(m => m.ClubId == clubId.Value);
            }
            
            // Order the query
            var orderedQuery = baseQuery.OrderBy(m => m.MatchDate);
            
            // Apply limit if needed
            if (count.HasValue)
            {
                baseQuery = orderedQuery.Take(count.Value);
            }
            else 
            {
                baseQuery = orderedQuery;
            }

            var matches = await baseQuery.ToListAsync();
            return matches.Select(m => MapToResponse(m)).ToList();
        }

        public async Task<List<MatchResponse>> GetRecentMatchesAsync(int? clubId = null, int? count = null)
        {
            // Create a simple IQueryable first
            IQueryable<Database.Match> baseQuery = _context.Matches
                .AsNoTracking()
                .Include(m => m.Club)
                .Include(m => m.Tickets)
                .ThenInclude(t => t.StadiumSector)
                .Where(m => m.MatchDate <= DateTime.UtcNow && m.HomeGoals.HasValue && m.AwayGoals.HasValue);
                
            // Apply club filter if needed
            if (clubId.HasValue)
            {
                baseQuery = baseQuery.Where(m => m.ClubId == clubId.Value);
            }
            
            // Order the query
            var orderedQuery = baseQuery.OrderByDescending(m => m.MatchDate);
            
            // Apply limit if needed
            if (count.HasValue)
            {
                baseQuery = orderedQuery.Take(count.Value);
            }
            else 
            {
                baseQuery = orderedQuery;
            }

            var matches = await baseQuery.ToListAsync();
            return matches.Select(m => MapToResponse(m)).ToList();
        }

        public async Task<MatchResponse> UpdateMatchResultAsync(int matchId, int homeGoals, int awayGoals)
        {
            var match = await _context.Matches.FindAsync(matchId);
            if (match == null)
                throw new Exception($"Match with ID {matchId} not found");

            match.HomeGoals = homeGoals;
            match.AwayGoals = awayGoals;
            match.Status = "Completed";

            await _context.SaveChangesAsync();
            return await GetByIdAsync(matchId);
        }

        public async Task<MatchResponse> UpdateMatchStatusAsync(int matchId, string status)
        {
            var match = await _context.Matches.FindAsync(matchId);
            if (match == null)
                throw new Exception($"Match with ID {matchId} not found");

            match.Status = status;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(matchId);
        }

        protected override IQueryable<Database.Match> ApplyFilter(IQueryable<Database.Match> query, MatchSearchObject search)
        {
            // Filter by club ID
            if (search.ClubId.HasValue)
            {
                query = query.Where(m => m.ClubId == search.ClubId.Value);
            }

            // Filter by date range
            if (search.FromDate.HasValue)
            {
                query = query.Where(m => m.MatchDate >= search.FromDate.Value);
            }

            if (search.ToDate.HasValue)
            {
                query = query.Where(m => m.MatchDate <= search.ToDate.Value);
            }

            // Filter by home/away matches
            if (search.IsHomeMatch.HasValue)
            {
                query = query.Where(m => m.IsHomeMatch == search.IsHomeMatch.Value);
            }

            // Filter by status
            if (!string.IsNullOrWhiteSpace(search.Status))
            {
                query = query.Where(m => m.Status == search.Status);
            }

            // Filter for upcoming matches
            if (search.UpcomingOnly == true)
            {
                query = query.Where(m => m.MatchDate > DateTime.UtcNow);
            }

            // Filter by text search
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                string searchTerm = search.FTS.Trim().ToLower();
                query = query.Where(m => 
                    m.OpponentName.ToLower().Contains(searchTerm) || 
                    m.Status.ToLower().Contains(searchTerm) ||
                    m.Club.Name.ToLower().Contains(searchTerm)
                );
            }

            return query;
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

                // Add tickets if provided
                if (request.Tickets != null && request.Tickets.Count > 0)
                {
                    foreach (var ticketRequest in request.Tickets)
                    {
                        var ticket = new MatchTicket
                        {
                            MatchId = entity.Id,
                            TotalQuantity = ticketRequest.TotalQuantity,
                            AvailableQuantity = ticketRequest.AvailableQuantity,
                            Price = ticketRequest.Price,
                            StadiumSectorId = ticketRequest.StadiumSectorId
                        };
                        
                        await _context.MatchTickets.AddAsync(ticket);
                    }
                    
                    await _context.SaveChangesAsync();
                }

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

                // Handle tickets update
                if (request.Tickets != null)
                {
                    // Remove existing tickets
                    _context.MatchTickets.RemoveRange(entity.Tickets);
                    await _context.SaveChangesAsync();

                    // Add new tickets
                    foreach (var ticketRequest in request.Tickets)
                    {
                        var ticket = new MatchTicket
                        {
                            MatchId = entity.Id,
                            TotalQuantity = ticketRequest.TotalQuantity,
                            AvailableQuantity = ticketRequest.AvailableQuantity,
                            Price = ticketRequest.Price,
                            StadiumSectorId = ticketRequest.StadiumSectorId
                        };
                        
                        await _context.MatchTickets.AddAsync(ticket);
                    }
                }

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

            // Validate stadium sectors exist
            if (request.Tickets != null && request.Tickets.Count > 0)
            {
                foreach (var ticket in request.Tickets)
                {
                    var sectorExists = await _context.StadiumSectors.AnyAsync(s => s.Id == ticket.StadiumSectorId);
                    if (!sectorExists)
                        throw new Exception($"Stadium sector with ID {ticket.StadiumSectorId} does not exist");
                }
            }

            return true;
        }

        protected override Database.Match MapInsertToEntity(Database.Match entity, MatchUpsertRequest request)
        {
            entity.MatchDate = request.MatchDate;
            entity.IsHomeMatch = request.IsHomeMatch;
            entity.OpponentName = request.OpponentName;
            entity.HomeGoals = request.HomeGoals;
            entity.AwayGoals = request.AwayGoals;
            entity.Status = request.Status;
            entity.ClubId = request.ClubId;
            entity.Tickets = new List<MatchTicket>();
            
            return entity;
        }

        protected override Database.Match MapUpdateToEntity(Database.Match entity, MatchUpsertRequest request)
        {
            entity.MatchDate = request.MatchDate;
            entity.IsHomeMatch = request.IsHomeMatch;
            entity.OpponentName = request.OpponentName;
            entity.HomeGoals = request.HomeGoals;
            entity.AwayGoals = request.AwayGoals;
            entity.Status = request.Status;
            entity.ClubId = request.ClubId;
            
            return entity;
        }

        private MatchResponse MapToResponse(Database.Match entity)
        {
            var response = _mapper.Map<MatchResponse>(entity);
            
            // Add club name
            response.ClubName = entity.Club?.Name;
            
            // Determine result string
            if (entity.HomeGoals.HasValue && entity.AwayGoals.HasValue)
            {
                string homeTeam = entity.IsHomeMatch ? entity.Club?.Name : entity.OpponentName;
                string awayTeam = entity.IsHomeMatch ? entity.OpponentName : entity.Club?.Name;
                int homeGoals = entity.IsHomeMatch ? entity.HomeGoals.Value : entity.AwayGoals.Value;
                int awayGoals = entity.IsHomeMatch ? entity.AwayGoals.Value : entity.HomeGoals.Value;
                
                response.Result = $"{homeTeam} {homeGoals} - {awayGoals} {awayTeam}";
            }
            
            // Map tickets
            if (entity.Tickets != null)
            {
                response.Tickets = entity.Tickets.Select(t => new MatchTicketResponse
                {
                    Id = t.Id,
                    MatchId = t.MatchId,
                    TotalQuantity = t.TotalQuantity,
                    AvailableQuantity = t.AvailableQuantity,
                    Price = t.Price,
                    StadiumSectorId = t.StadiumSectorId,
                    SectorName = t.StadiumSector?.Code,
                    SectorColor = null // StadiumSector doesn't have a Color property, so set to null
                }).ToList();
            }
            
            return response;
        }
    }
}