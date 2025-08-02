import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_desktop/models/match.dart';
import 'package:myclub_desktop/models/match_ticket_upsert_request.dart';
import 'package:myclub_desktop/providers/match_provider.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchProvider(),
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
  
  List<Match> _upcomingMatches = [];
  Match? _selectedMatch;
  bool _isLoading = false;
  bool _isLoadingTickets = false;
  
  // Stadium sectors mapping (hardcoded based on your seeder)
  final Map<String, List<Map<String, dynamic>>> _stadiumSectors = {
    'Jug': [
      {'id': 1, 'code': 'A1', 'capacity': 100},
      {'id': 2, 'code': 'A2', 'capacity': 100},
    ],
    'Zapad': [
      {'id': 3, 'code': 'B1', 'capacity': 100},
      {'id': 4, 'code': 'B2', 'capacity': 100},
      {'id': 5, 'code': 'B3', 'capacity': 100},
    ],
    'Sjever': [
      {'id': 6, 'code': 'C1', 'capacity': 100},
      {'id': 7, 'code': 'C2', 'capacity': 100},
    ],
    'Istok': [
      {'id': 8, 'code': 'D1', 'capacity': 100},
      {'id': 9, 'code': 'D2', 'capacity': 100},
      {'id': 10, 'code': 'D3', 'capacity': 100},
    ],
  };
  
  // Form values for each sector
  final Map<int, Map<String, dynamic>> _sectorValues = {};
  // Existing tickets for the selected match
  Map<int, Map<String, dynamic>> _existingTickets = {};

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _loadData();
  }

  void _initializeProvider() {
    _matchProvider = context.read<MatchProvider>();
    _matchProvider.setContext(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _upcomingMatches = await _matchProvider.getUpcomingMatches();
      if (_upcomingMatches.isNotEmpty) {
        _selectedMatch = _upcomingMatches.first;
        await _loadTicketsForMatch();
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: "Greška tokom učitavanja utakmica: ${_formatErrorMessage(e)}",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTicketsForMatch() async {
    if (_selectedMatch == null) return;

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final tickets = await _matchProvider.getTicketsForMatch(_selectedMatch!.id!);
      
      setState(() {
        _existingTickets.clear();
        for (var ticket in tickets) {
          int sectorId = ticket['stadiumSectorId'];
          _existingTickets[sectorId] = ticket;
          
          // Pre-fill form with existing values
          _sectorValues[sectorId] = {
            'quantity': ticket['releasedQuantity'] ?? 0,
            'price': ticket['price'] ?? 0.0,
          };
        }
      });
    } catch (e) {
      // It's okay if there are no tickets yet
      setState(() {
        _existingTickets.clear();
      });
    } finally {
      setState(() {
        _isLoadingTickets = false;
      });
    }
  }

  String _formatErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring('Exception: '.length);
    }
    return errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchSlider(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildStadiumForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSlider() {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Izaberi utakmicu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
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
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingMatches.length,
                    itemBuilder: (context, index) {
                      final match = _upcomingMatches[index];
                      final isSelected = _selectedMatch?.id == match.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMatch = match;
                            _sectorValues.clear();
                          });
                          _loadTicketsForMatch();
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 15),
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
                                color: Colors.grey.withValues(alpha: 0.1),
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
                                      color: isSelected ? Colors.white : Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      match.opponentName ?? 'Nepoznat',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                match.matchDate != null 
                                    ? DateFormat('dd.MM.\nHH:mm').format(match.matchDate!)
                                    : 'TBD',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumForm() {
    if (_selectedMatch == null) {
      return const Center(
        child: Text(
          'Molim izaberite utakmicu za konfiguraciju ulaznica',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stadium Layout
          Expanded(
            child: Row(
              children: [
                // Left side (Zapad)
                Expanded(
                  child: _buildSideColumn('Zapad', _stadiumSectors['Zapad']!),
                ),
                
                // Center columns (Istok and Sjever)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSideColumn('Istok', _stadiumSectors['Istok']!),
                      ),
                      Expanded(
                        child: _buildSideColumn('Sjever', _stadiumSectors['Sjever']!),
                      ),
                    ],
                  ),
                ),
                
                // Right side (Jug)
                Expanded(
                  child: _buildSideColumn('Jug', _stadiumSectors['Jug']!),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Add tickets button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingTickets ? null : _addTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingTickets
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Dodaj/Ažuriraj ulaznice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideColumn(String sideName, List<Map<String, dynamic>> sectors) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            sideName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          
          Expanded(
            child: ListView(
              children: sectors.map((sector) => 
                _buildSectorField(sector)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorField(Map<String, dynamic> sector) {
    final sectorId = sector['id'];
    final existingTicket = _existingTickets[sectorId];
    final hasExistingTicket = existingTicket != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasExistingTicket ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasExistingTicket ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sector['code'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasExistingTicket) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Aktivno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasExistingTicket) ...[
            const SizedBox(height: 4),
            Text(
              'Trenutno: ${existingTicket['releasedQuantity']} ulaznica po ${existingTicket['price']} KM',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          
          // Input fields in a row
          Row(
            children: [
              // Quantity field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Količina',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: ValueKey('quantity_${sector['id']}'),
                      initialValue: _sectorValues[sectorId]?['quantity']?.toString() ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Unesite količinu',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        _updateSectorValue(sector['id'], 'quantity', int.tryParse(value) ?? 0);
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
                    const Text(
                      'Cijena (KM)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: ValueKey('price_${sector['id']}'),
                      initialValue: _sectorValues[sectorId]?['price']?.toString() ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Unesite cijenu',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (value) {
                        _updateSectorValue(sector['id'], 'price', double.tryParse(value) ?? 0.0);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateSectorValue(int sectorId, String field, dynamic value) {
    setState(() {
      if (!_sectorValues.containsKey(sectorId)) {
        _sectorValues[sectorId] = {};
      }
      _sectorValues[sectorId]![field] = value;
    });
  }

  Future<void> _addTickets() async {
    if (_selectedMatch == null) return;

    try {
      List<Map<String, dynamic>> tickets = [];

      for (var entry in _sectorValues.entries) {
        int sectorId = entry.key;
        Map<String, dynamic> values = entry.value;
        
        int quantity = values['quantity'] ?? 0;
        double price = values['price'] ?? 0.0;
        
        if (quantity > 0 && price > 0) {
          final ticket = MatchTicketUpsertRequest(
            matchId: _selectedMatch!.id!,
            releasedQuantity: quantity,
            price: price,
            stadiumSectorId: sectorId,
          );
          
          tickets.add(ticket.toJson());
        }
      }

      if (tickets.isNotEmpty) {
        await _matchProvider.addTicketsForMatch(_selectedMatch!.id!, tickets);
        
        NotificationUtility.showSuccess(
          context,
          message: 'Ulaznice su uspješno dodane/ažurirane!',
        );
        
        // Reload tickets to show updated data
        await _loadTicketsForMatch();
      } else {
        NotificationUtility.showWarning(
          context,
          message: 'Molim unesite količinu i cijenu za najmanje jedan sektor',
        );
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška tokom dodavanja ulaznica: ${_formatErrorMessage(e)}',
      );
    }
  }
}
