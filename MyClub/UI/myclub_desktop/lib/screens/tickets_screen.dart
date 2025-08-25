import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_desktop/models/match.dart';
import 'package:myclub_desktop/models/match_ticket.dart';
import 'package:myclub_desktop/models/match_ticket_upsert_request.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/models/search_objects/base_search_object.dart';
import 'package:myclub_desktop/models/stadium_sector.dart';
import 'package:myclub_desktop/providers/match_provider.dart';
import 'package:myclub_desktop/providers/stadium_sector_provider.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => StadiumSectorProvider()),
      ],
      child: const _TicketsContent(),
    );
  }
}

class _TicketsContent extends StatefulWidget {
  const _TicketsContent({Key? key}) : super(key: key);

  @override
  _TicketsContentState createState() => _TicketsContentState();
}

class _TicketsContentState extends State<_TicketsContent> {
  late MatchProvider _matchProvider;
  late StadiumSectorProvider _stadiumSectorProvider;
  
  // Form key for proper form state management
  // Using separate keys for different forms to avoid widget tree conflicts
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _addTicketsFormKey = GlobalKey<FormState>();
  
  // Form rebuild counter to force TextFormField recreation
  int _formRebuildCounter = 0;
  
  List<Match> _upcomingMatches = [];
  List<StadiumSector> _stadiumSectors = [];
  Match? _selectedMatch;
  bool _isLoading = false;
  bool _isLoadingTickets = false;
  
  // Form values for each sector
  final Map<int, Map<String, dynamic>> _sectorValues = {};
  // Existing tickets for the selected match
  Map<int, MatchTicket> _existingTickets = {};
  // Validation errors for each sector
  Map<int, String?> _sectorValidationErrors = {};
  
  // ScrollController for the horizontal matches scroll
  final ScrollController _matchesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeProviders();
    _loadData();
  }

  void _initializeProviders() {
    _matchProvider = context.read<MatchProvider>();
    _matchProvider.setContext(context);
    
    _stadiumSectorProvider = context.read<StadiumSectorProvider>();
    _stadiumSectorProvider.setContext(context);
  }

  @override
  void dispose() {
    _matchesScrollController.dispose();
    super.dispose();
  }

  String _formatErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring('Exception: '.length);
    }
    return errorMessage;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load both matches and stadium sectors in parallel
      final matchesFuture = _matchProvider.getUpcomingMatches();

      BaseSearchObject sectorSearch = BaseSearchObject(retrieveAll: true);
      final sectorsFuture = _stadiumSectorProvider.get(searchObject: sectorSearch);
      
      final results = await Future.wait([matchesFuture, sectorsFuture]);
      
      if (!mounted) return;
      
      _upcomingMatches = results[0] as List<Match>;
      final sectorsResult = results[1] as PagedResult<StadiumSector>;
      
      // Extract stadium sectors from paged result - stadium side should now come from backend
      _stadiumSectors = sectorsResult.data;
      
      // Sort stadium sectors by sector code in ascending order
      _stadiumSectors.sort((a, b) => a.code.compareTo(b.code));
      
      // Auto-select first match if available
      if (_upcomingMatches.isNotEmpty) {
        _selectedMatch = _upcomingMatches.first;
        _loadTicketsFromSelectedMatch();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationUtility.showError(
        context,
        message: "Greška tokom učitavanja podataka: ${_formatErrorMessage(e)}",
      );
      print("Error loading data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadTicketsFromSelectedMatch() {

    _clearForm();
    if (_selectedMatch == null || !mounted) return;

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      // Use tickets data from the selected match (already loaded from API)
      final tickets = _selectedMatch!.tickets ?? [];
      
      if (!mounted) return;
      
      setState(() {
        _existingTickets.clear();
        _sectorValues.clear(); // Clear first
        _sectorValidationErrors.clear(); // Clear validation errors
        
        // Group tickets by sector and sum quantities and prices
        Map<int, List<MatchTicket>> ticketsBySector = {};
        
        for (var ticket in tickets) {
          if (ticket.stadiumSector != null) {
            int sectorId = ticket.stadiumSector!.id;
            if (!ticketsBySector.containsKey(sectorId)) {
              ticketsBySector[sectorId] = [];
            }
            ticketsBySector[sectorId]!.add(ticket);
          }
        }
        
        // Initialize values for ALL sectors with empty values
        for (var sector in _stadiumSectors) {
          // Always initialize with empty values (don't prefill anything)
          _sectorValues[sector.id] = {
            'quantity': null, // Empty quantity
            'price': null,    // Empty price
          };
        }
        
        // Process each sector that has tickets
        for (var entry in ticketsBySector.entries) {
          int sectorId = entry.key;
          List<MatchTicket> sectorTickets = entry.value;
          
          // Calculate total quantities for this sector
          int totalReleasedQuantity = sectorTickets.fold(0, (sum, ticket) => sum + (ticket.releasedQuantity ?? 0));
          int totalAvailableQuantity = sectorTickets.fold(0, (sum, ticket) => sum + (ticket.availableQuantity ?? 0));
          int totalUsedQuantity = sectorTickets.fold(0, (sum, ticket) => sum + (ticket.usedQuantity ?? 0));
          
          // Use the latest price (from the last ticket)
          double latestPrice = sectorTickets.last.price ?? 0.0;
          
          // Create a combined ticket object
          MatchTicket combinedTicket = MatchTicket(
            id: sectorTickets.first.id, // Use first ticket's ID
            matchId: sectorTickets.first.matchId,
            stadiumSector: sectorTickets.first.stadiumSector,
            releasedQuantity: totalReleasedQuantity,
            price: latestPrice,
            availableQuantity: totalAvailableQuantity,
            usedQuantity: totalUsedQuantity,
          );
          
          _existingTickets[sectorId] = combinedTicket;
          
          // Don't pre-fill any form values - keep them empty
          // This ensures all fields start empty regardless of existing tickets
          
          print("DEBUG: Sector $sectorId has ${sectorTickets.length} tickets with total quantity: $totalReleasedQuantity");
        }
      });
    } catch (e) {
      // It's okay if there are no tickets yet
      if (mounted) {
        setState(() {
          _existingTickets.clear();
          _sectorValues.clear();
          _sectorValidationErrors.clear(); // Clear validation errors
          
          // Initialize all sectors with empty values
          for (var sector in _stadiumSectors) {
            _sectorValues[sector.id] = {
              'quantity': null,
              'price': null,
            };
          }
        });
      }
      print("Error loading tickets: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

    void _updateSectorValue(int sectorId, String field, dynamic value) {
    setState(() {
      if (!_sectorValues.containsKey(sectorId)) {
        _sectorValues[sectorId] = {};
      }
      _sectorValues[sectorId]![field] = value;
      
      // Clear validation error for this sector when user starts typing
      if (_sectorValidationErrors.containsKey(sectorId)) {
        _sectorValidationErrors.remove(sectorId);
      }
    });
  }

  Future<void> _addTickets() async {
    if (_selectedMatch == null || !mounted) return;

    // Clear previous validation errors
    setState(() {
      _sectorValidationErrors.clear();
    });

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      List<Map<String, dynamic>> tickets = [];
      bool hasValidationErrors = false;

      // Check if user has actually entered any data before validating
      bool hasUserInput = false;
      for (var entry in _sectorValues.entries) {
        Map<String, dynamic> values = entry.value;
        int quantity = values['quantity'] ?? 0;
        
        if (quantity > 0) {
          hasUserInput = true;
          break;
        }
      }
      
      // If no user input, show validation error
      if (!hasUserInput) {
        if (!mounted) return;
        
        NotificationUtility.showError(
          context,
          message: 'Morate dodati karte za najmanje 1 sektor',
        );
        
        setState(() {
          _isLoadingTickets = false;
        });
        return;
      }
      
      print("DEBUG: User has input, proceeding with validation...");

      for (var entry in _sectorValues.entries) {
        int sectorId = entry.key;
        Map<String, dynamic> values = entry.value;
        
        int quantity = values['quantity'] ?? 0;
        double price = values['price'] ?? 0.0;
        
        // Get sector information for validation error messages
        final sector = _stadiumSectors.firstWhere(
          (s) => s.id == sectorId,
          orElse: () => _stadiumSectors.isNotEmpty 
              ? _stadiumSectors.first 
              : StadiumSector(id: 0, capacity: 0, code: 'Nepoznat')
        );
        
        // Check if there's an existing ticket for this sector
        final existingTicket = _existingTickets[sectorId];
        final currentReleasedQuantity = existingTicket?.releasedQuantity ?? 0;
        final existingPrice = existingTicket?.price;
        
        // If this sector has any input (quantity or price), validate it
        if (quantity > 0 || price > 0) {
          // For sectors with existing tickets, only quantity is required (use existing price)
          // For new sectors, both quantity and price are required
          if (existingPrice != null) {
            // Sector has existing tickets - only validate quantity
            if (quantity <= 0) {
              setState(() {
                _sectorValidationErrors[sectorId] = 'Molim unesite količinu';
              });
              hasValidationErrors = true;
              continue;
            }
            // Use existing price instead of user input
            price = existingPrice;
          } else {
            // New sector - both quantity and price must be provided
            if (quantity <= 0 || price <= 0) {
              setState(() {
                _sectorValidationErrors[sectorId] = 'Molim unesite i količinu i cijenu';
              });
              hasValidationErrors = true;
              continue;
            }
          }
          
          // IMPORTANT: The form shows existing quantity, user enters ADDITIONAL quantity
          // So we need to calculate: currentReleasedQuantity + newQuantityToAdd
          final newQuantityToAdd = quantity;
          final totalAfterAddition = currentReleasedQuantity + newQuantityToAdd;
          
          print("DEBUG: Sector ${sector.code}: Current=$currentReleasedQuantity, Adding=$newQuantityToAdd, Total will be=$totalAfterAddition");
          
          // Frontend validation: Check if total after addition exceeds sector capacity
          if (totalAfterAddition > sector.capacity) {
            final maxCanAdd = sector.capacity - currentReleasedQuantity;
            if (maxCanAdd <= 0) {
              setState(() {
                _sectorValidationErrors[sectorId] = 'Sektor je popunjen (${currentReleasedQuantity}/${sector.capacity})';
              });
            } else {
              setState(() {
                _sectorValidationErrors[sectorId] = 'Maksimalno možete dodati ${maxCanAdd} ulaznica';
              });
            }
            hasValidationErrors = true;
            continue;
          }
          
          // If sector already has reached capacity, don't allow any additions
          if (currentReleasedQuantity >= sector.capacity) {
            setState(() {
              _sectorValidationErrors[sectorId] = 'Sektor je popunjen';
            });
            hasValidationErrors = true;
            continue;
          }
          
          print("DEBUG: Sector ${sector.code}: Validation passed, adding $newQuantityToAdd tickets");
          
          final ticket = MatchTicketUpsertRequest(
            matchId: _selectedMatch!.id!,
            releasedQuantity: newQuantityToAdd, // Send only the additional quantity
            price: price,
            stadiumSectorId: sectorId,
          );
          
          tickets.add(ticket.toJson());
        }
      }

      // If there are validation errors, don't proceed
      if (hasValidationErrors) {
        print("DEBUG: Validation failed");
        if (!mounted) return;
        setState(() {
          _isLoadingTickets = false;
        });
        return;
      }
      
      print("DEBUG: Validation passed, proceeding with ${tickets.length} tickets");

      if (tickets.isNotEmpty) {
        await _matchProvider.addTicketsForMatch(_selectedMatch!.id!, tickets);
        
        if (!mounted) return;
        
        // Show success message
        NotificationUtility.showSuccess(context, message: "Ulaznice uspješno dodane");
        
        // Clear the form after successful operation (keeps selected match)
        _clearForm();
        
        // Refresh the current match with updated ticket data
        await _refreshCurrentMatchTickets();
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = _formatErrorMessage(e);
      print("Error in _addTickets: $errorMessage");
      
      // For backend errors, we'll just log them and not show notifications
      // The validation should be handled by the frontend visual feedback
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  void _clearForm() {
    if (_selectedMatch == null) return;
    
    // Only reset the form fields without rebuilding the entire form
    setState(() {
      // Clear the sector values but keep the form state
      _sectorValues.clear();
      _sectorValidationErrors.clear(); // Clear validation errors
      
      // Don't attempt to initialize sectors if they're not loaded yet
      if (_stadiumSectors.isNotEmpty) {
        // Initialize empty values for all sectors
        for (var sector in _stadiumSectors) {
          _sectorValues[sector.id] = {
            'quantity': null,
            'price': null,
          };
        }
      }
      
      // Increment rebuild counter to force TextFormFields to rebuild with empty values
      _formRebuildCounter++;
      
      print('Ticket form has been cleared successfully (rebuild #$_formRebuildCounter) - Match preserved');
    });
    
    // Don't call reset() directly inside setState to avoid widget tree conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only reset if still mounted and state exists
      if (mounted) {
        if (_addTicketsFormKey.currentState != null) {
          _addTicketsFormKey.currentState!.reset();
        }
        // Use a safer approach with _formKey - check if mounted first
        if (_formKey.currentState != null) {
          _formKey.currentState!.reset();
        }
      }
    });
  }

  Future<void> _refreshCurrentMatchTickets() async {
    if (_selectedMatch == null || !mounted) return;

    try {
      // Reload the specific match with updated ticket data
      final updatedMatch = await _matchProvider.getUpcomingMatches();
      final currentMatch = updatedMatch.firstWhere(
        (match) => match.id == _selectedMatch!.id,
        orElse: () => _selectedMatch!,
      );
      
      if (!mounted) return;
      
      setState(() {
        _selectedMatch = currentMatch;
      });
      
      // Now reload the tickets from the updated match
      _loadTicketsFromSelectedMatch();
    } catch (e) {
      if (!mounted) return;
      print("Error refreshing match tickets: $e");
      // Fallback to loading from current match data
      _loadTicketsFromSelectedMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match selection section
              Container(
                height: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Izaberi utakmicu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Match cards area 
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _upcomingMatches.isEmpty
                          ? const Center(
                              child: Text(
                                'Nema predstojećih utakmica',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : Column(
                              children: [
                                // Match cards in their own scrolling container with scrollbar
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15.0, bottom: 15.0), // Margin between scrollbar and content
                                    child: Scrollbar(
                                      controller: _matchesScrollController,
                                      thickness: 6,
                                      radius: Radius.circular(10),
                                      thumbVisibility: true,
                                      interactive: true,
                                      child: SingleChildScrollView(
                                        controller: _matchesScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Row(
                                        children: _upcomingMatches.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final match = entry.value;
                                          final isSelected = _selectedMatch?.id == match.id;
                                          
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedMatch = match;
                                                _sectorValues.clear();
                                              });
                                              _loadTicketsFromSelectedMatch();
                                            },
                                            child: Container(
                                              width: 180,
                                              margin: EdgeInsets.only(
                                                top: 5.0, // Add top margin to cards
                                                right: index < _upcomingMatches.length - 1 ? 15 : 0,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.blue[600] : Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.1),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: isSelected ? Colors.white : Colors.blue[600],
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          match.opponentName ?? 'Nepoznat',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: isSelected ? Colors.white : Colors.black87,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    match.matchDate != null 
                                                        ? DateFormat('dd.MM.yyyy').format(match.matchDate!)
                                                        : 'TBD',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w500,
                                                      color: isSelected ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    match.matchDate != null 
                                                        ? DateFormat('HH:mm').format(match.matchDate!)
                                                        : '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isSelected ? Colors.white70 : Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                          )],
                            ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            
            // Stadium Form Section
            Expanded(
              child: _selectedMatch == null
                ? const Center(
                    child: Text(
                      'Molim izaberite utakmicu za konfiguraciju ulaznica',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // Use Flex layout to ensure content fits
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                      // Title row - compact
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sektori stadiona - ${_selectedMatch!.opponentName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (_isLoadingTickets)
                            const SizedBox(
                              width: 16, // Reduced size
                              height: 16, // Reduced size
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10), // Reduced spacing
                      
                      // Flexible content area - takes all remaining space
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side - Existing Ticket Information
                            Expanded(
                              flex: 3,
                              child: Container(
                                  margin: const EdgeInsets.only(right: 8), // Reduced margin
                                  padding: const EdgeInsets.all(12), // Reduced padding
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.stadium, color: Colors.blue[600], size: 24),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Trenutno stanje ulaznica po sektorima',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      Expanded(
                                        child: _existingTickets.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.inbox_outlined, 
                                                       size: 64, 
                                                       color: Colors.grey[400]),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Nema izdanih ulaznica za ovu utakmicu',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : GridView.builder(
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 2.2,
                                                crossAxisSpacing: 12,
                                                mainAxisSpacing: 12,
                                              ),
                                              itemCount: _existingTickets.length,
                                              itemBuilder: (context, index) {
                                                final entry = _existingTickets.entries.elementAt(index);
                                                final sectorId = entry.key;
                                                final ticket = entry.value;
                                                
                                                final sector = _stadiumSectors.firstWhere(
                                                  (s) => s.id == sectorId,
                                                  orElse: () => StadiumSector(id: 0, capacity: 0, code: 'Nepoznat')
                                                );
                                                
                                                final isOverLimit = (ticket.releasedQuantity ?? 0) > sector.capacity;
                                                
                                                return Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: isOverLimit ? Colors.red[50] : Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: isOverLimit ? Colors.red[200]! : Colors.green[200]!,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey.withValues(alpha: 0.1),
                                                        spreadRadius: 1,
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isOverLimit ? Colors.red : Colors.green,
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              sector.code,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            sector.stadiumSide?.name ?? 'Nepoznato',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          if (isOverLimit) ...[
                                                            const Spacer(),
                                                            Icon(Icons.warning, 
                                                                 color: Colors.red[600], 
                                                                 size: 16),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Icon(Icons.confirmation_number, 
                                                                     size: 16, 
                                                                     color: Colors.blue[600]),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  '${ticket.releasedQuantity ?? 0}',
                                                                  style: TextStyle(
                                                                    fontSize: 20,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: isOverLimit ? Colors.red[700] : Colors.black87,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'ulaznica',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${ticket.price?.toStringAsFixed(2) ?? '0.00'} KM',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            
                                                            Row(
                                                              children: [
                                                                Icon(Icons.check_circle_outline, 
                                                                     size: 14, 
                                                                     color: Colors.orange[600]),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'Dostupno: ${ticket.availableQuantity ?? 0}',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            
                                                            Row(
                                                              children: [
                                                                Icon(Icons.how_to_reg, 
                                                                     size: 14, 
                                                                     color: Colors.purple[600]),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'Iskorišteno: ${ticket.usedQuantity ?? 0}',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Right Side - Add Tickets Form
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8), // Reduced margin
                                  padding: const EdgeInsets.all(12), // Reduced padding
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _addTicketsFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.add_circle, color: Colors.blue[600], size: 24),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Dodaj nove ulaznice',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Maksimalna količina ovisi o kapacitetu sektora',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _stadiumSectors.length,
                                            itemBuilder: (context, index) {
                                              final sector = _stadiumSectors[index];
                                              final sectorId = sector.id;
                                              final existingTicket = _existingTickets[sectorId];
                                              final currentQuantity = existingTicket?.releasedQuantity ?? 0;
                                              final existingPrice = existingTicket?.price;
                                              final maxCanAdd = math.max(0, sector.capacity - currentQuantity);
                                              final canAddTickets = maxCanAdd > 0;
                                              final hasValidationError = _sectorValidationErrors.containsKey(sectorId);
                                              final validationError = _sectorValidationErrors[sectorId];
                                              
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 16),
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: hasValidationError 
                                                      ? Colors.red[50] 
                                                      : (canAddTickets ? Colors.grey[50] : Colors.red[50]),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: hasValidationError 
                                                        ? Colors.red[400]! 
                                                        : (canAddTickets ? Colors.grey[200]! : Colors.red[200]!),
                                                    width: hasValidationError ? 2 : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: canAddTickets ? Colors.blue : Colors.red,
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            sector.code,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          sector.sideName ?? 'Nepoznato',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        if (existingTicket != null)
                                                          Text(
                                                            'Trenutno: $currentQuantity',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    
                                                    if (!canAddTickets) ...[
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red[100],
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.block, color: Colors.red[600], size: 16),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Sektor je popunjen (${currentQuantity}/${sector.capacity})',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.red[700],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // Quantity field
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Dodatne ulaznice (max $maxCanAdd)',
                                                                  style: const TextStyle(
                                                                    fontSize: 12, 
                                                                    fontWeight: FontWeight.w500
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                TextFormField(
                                                                  key: ValueKey('quantity_${sector.id}_$_formRebuildCounter'),
                                                                  initialValue: '', // Always empty
                                                                  enabled: canAddTickets,
                                                                  decoration: InputDecoration(
                                                                    hintText: 'Broj dodatnih',
                                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    border: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.grey[300]!,
                                                                      ),
                                                                    ),
                                                                    enabledBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.grey[300]!,
                                                                      ),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.blue[600]!,
                                                                      ),
                                                                    ),
                                                                    isDense: true,
                                                                    fillColor: canAddTickets ? Colors.white : Colors.grey[100],
                                                                    filled: true,
                                                                  ),
                                                                  style: const TextStyle(fontSize: 14),
                                                                  keyboardType: TextInputType.number,
                                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                  onChanged: (value) {
                                                                    _updateSectorValue(sector.id, 'quantity', int.tryParse(value) ?? 0);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          
                                                          // Price field
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Cijena (KM)',
                                                                  style: const TextStyle(
                                                                    fontSize: 12, 
                                                                    fontWeight: FontWeight.w500
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                TextFormField(
                                                                  key: ValueKey('price_${sector.id}_$_formRebuildCounter'),
                                                                  initialValue: existingPrice != null ? existingPrice.toStringAsFixed(2) : '',
                                                                  enabled: canAddTickets && existingPrice == null,
                                                                  decoration: InputDecoration(
                                                                    hintText: existingPrice != null 
                                                                        ? 'Postojeća: ${existingPrice.toStringAsFixed(2)} KM' 
                                                                        : 'Unesite cijenu',
                                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    border: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.grey[300]!,
                                                                      ),
                                                                    ),
                                                                    enabledBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.grey[300]!,
                                                                      ),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: hasValidationError ? Colors.red[400]! : Colors.blue[600]!,
                                                                      ),
                                                                    ),
                                                                    isDense: true,
                                                                    fillColor: existingPrice != null 
                                                                        ? Colors.grey[100] 
                                                                        : (canAddTickets ? Colors.white : Colors.grey[100]),
                                                                    filled: true,
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize: 14,
                                                                    color: existingPrice != null ? Colors.grey[600] : null,
                                                                  ),
                                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                                                  onChanged: (value) {
                                                                    if (existingPrice == null) {
                                                                      _updateSectorValue(sector.id, 'price', double.tryParse(value) ?? 0.0);
                                                                    }
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      
                                                      // Show price info below the fields if existing price
                                                      if (existingPrice != null) ...[
                                                        const SizedBox(height: 8),
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue[50],
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: Colors.blue[200]!),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Postojeća cijena ${existingPrice.toStringAsFixed(2)} KM će biti zadržana',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.blue[700],
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      
                                                      // Show validation error if exists
                                                      if (hasValidationError && validationError != null) ...[
                                                        const SizedBox(height: 8),
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red[100],
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: Colors.red[300]!),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  validationError,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.red[700],
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        
                                        // Action buttons
                                        Row(
                                          children: [
                                            // Cancel button
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: _isLoadingTickets ? null : _clearForm,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey[600],
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Otkaži',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            
                                            // Add tickets button
                                            Expanded(
                                              flex: 2,
                                              child: ElevatedButton(
                                                onPressed: _isLoadingTickets ? null : _addTickets,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue[600],
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: _isLoadingTickets
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Dodaj ulaznice',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    ));
  }
}
