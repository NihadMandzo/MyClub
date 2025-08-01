import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:myclub_desktop/models/match.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/models/search_objects/match_search_object.dart';
import 'package:myclub_desktop/providers/match_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchProvider(),
      child: const _MatchesContent(),
    );
  }
}

class _MatchesContent extends StatefulWidget {
  const _MatchesContent({Key? key}) : super(key: key);

  @override
  _MatchesContentState createState() => _MatchesContentState();
}

class _MatchesContentState extends State<_MatchesContent> {
  late MatchProvider _matchProvider;

  final TextEditingController _searchController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Match? _selectedMatch;
  PagedResult<Match>? _result;
  bool _isLoading = false;

  // Form fields
  final TextEditingController _opponentNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _homeScoreController = TextEditingController();
  final TextEditingController _awayScoreController = TextEditingController();
  DateTime? _selectedMatchDate;
  String? _selectedStatus;
  bool _showResultForm = false;

  // Search fields
  MatchSearchObject _searchObject = MatchSearchObject(
    page: 0,
    pageSize: 10,
  );

  final List<String> _statusOptions = [
    'Zakazana',
    'Uživo',
    'Završena',
    'Otkazana',
    'Odložena'
  ];

  @override
  void initState() {
    super.initState();
    _matchProvider = Provider.of<MatchProvider>(context, listen: false);
    _matchProvider.setContext(context);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _opponentNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _matchProvider.get(searchObject: _searchObject);
      setState(() {
        _result = result;
      });
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search() {
    _searchObject = MatchSearchObject(
      fts: _searchController.text.isEmpty ? null : _searchController.text,
      page: 0,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePage(int newPage) {
    _searchObject = MatchSearchObject(
      fts: _searchObject.fts,
      page: newPage,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePageSize(int? pageSize) {
    if (pageSize != null) {
      _searchObject = MatchSearchObject(
        fts: _searchObject.fts,
        page: 0,
        pageSize: pageSize,
      );
      _loadData();
    }
  }

  List<Widget> _buildPageNumbers() {
    if (_result == null) return [];

    final currentPage = (_searchObject.page ?? 0);
    final totalPages = _result!.totalPages;
    final List<Widget> pageWidgets = [];

    const int maxDisplayedPages = 5;

    if (totalPages <= maxDisplayedPages) {
      for (int i = 0; i < totalPages; i++) {
        pageWidgets.add(_buildPageButton(i));
      }
    } else {
      pageWidgets.add(_buildPageButton(0));

      int startPage = (currentPage - 1).clamp(1, totalPages - 2);
      int endPage = (currentPage + 1).clamp(2, totalPages - 2);

      if (endPage - startPage < maxDisplayedPages - 3) {
        if (startPage == 1) {
          endPage = math.min(maxDisplayedPages - 2, totalPages - 2);
        } else if (endPage == totalPages - 2) {
          startPage = math.max(1, totalPages - maxDisplayedPages + 1);
        }
      }

      if (startPage > 1) {
        pageWidgets.add(
          const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }

      for (int i = startPage; i <= endPage; i++) {
        pageWidgets.add(_buildPageButton(i));
      }

      if (endPage < totalPages - 2) {
        pageWidgets.add(
          const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }

      if (totalPages > 1) {
        pageWidgets.add(_buildPageButton(totalPages - 1));
      }
    }

    return pageWidgets;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == (_searchObject.page ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: isCurrentPage ? null : () => _changePage(page),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPage ? Colors.blue.shade700 : Colors.blue.shade200,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          disabledBackgroundColor: Colors.blue.shade700,
        ),
        child: Text('${page + 1}'),
      ),
    );
  }

  void _selectMatch(Match match) async {
    setState(() {
      _isLoading = true;
      _selectedMatch = match;
    });

    try {
      final detailedMatch = await _matchProvider.getById(match.id!);

      _opponentNameController.text = detailedMatch.opponentName ?? '';
      _locationController.text = detailedMatch.location ?? '';
      _descriptionController.text = detailedMatch.description ?? '';
      _homeScoreController.text = detailedMatch.result?.homeGoals?.toString() ?? '';
      _awayScoreController.text = detailedMatch.result?.awayGoals?.toString() ?? '';
      _selectedMatchDate = detailedMatch.matchDate;
      _selectedStatus = detailedMatch.status;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });

    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška pri učitavanju detalja: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    // First reset the form state to clear validators
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
    
    setState(() {
      // Reset match selection and state variables
      _selectedMatch = null;
      _selectedMatchDate = null;
      _selectedStatus = null;
      _showResultForm = false;
      
      // Clear all text controllers
      _opponentNameController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _homeScoreController.clear();
      _awayScoreController.clear();
    });
    
    // Rebuild the UI to ensure all validators are refreshed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // This triggers a rebuild after the frame is done
      });
    });
    
    print("Match form has been cleared successfully");
  }

  bool _isFormPopulated() {
    final opponentFilled = _opponentNameController.text.trim().isNotEmpty;
    final locationFilled = _locationController.text.trim().isNotEmpty;
    final descriptionFilled = _descriptionController.text.trim().isNotEmpty;
    final dateFilled = _selectedMatchDate != null;
    final statusFilled = _selectedStatus != null && _selectedStatus!.trim().isNotEmpty;
    
    return opponentFilled || locationFilled || descriptionFilled || dateFilled || statusFilled;
  }

  Future<void> _populateFormForEditing() async {
    if (_selectedMatch == null) return;

    // Show confirmation dialog for editing
    final confirmed = await DialogUtility.showConfirmation(
      context,
      title: 'Potvrdi uređivanje',
      message: 'Da li želite urediti meč protiv ${_selectedMatch!.opponentName}?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final detailedMatch = await _matchProvider.getById(_selectedMatch!.id!);

      _opponentNameController.text = detailedMatch.opponentName ?? '';
      _locationController.text = detailedMatch.location ?? '';
      _descriptionController.text = detailedMatch.description ?? '';
      _homeScoreController.text = detailedMatch.result?.homeGoals?.toString() ?? '';
      _awayScoreController.text = detailedMatch.result?.awayGoals?.toString() ?? '';
      _selectedMatchDate = detailedMatch.matchDate;
      _selectedStatus = detailedMatch.status;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });

    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška pri učitavanju detalja: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await DialogUtility.showConfirmation(
      context,
      title: _selectedMatch == null ? 'Potvrdi dodavanje' : 'Potvrdi izmjene',
      message: _selectedMatch == null 
          ? 'Da li ste sigurni da želite dodati novi meč protiv ${_opponentNameController.text}?'
          : 'Da li ste sigurni da želite sačuvati izmjene za meč protiv ${_opponentNameController.text}?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final match = Match(
        id: _selectedMatch?.id,
        opponentName: _opponentNameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        matchDate: _selectedMatchDate,
        status: _selectedStatus,
        clubId: 1, // Always set to 1 as this is your club's application
      );

      if (_selectedMatch == null) {
        await _matchProvider.insert(match);
        NotificationUtility.showSuccess(context, message: 'Meč je uspješno dodan!');
      } else {
        await _matchProvider.update(_selectedMatch!.id!, match);
        NotificationUtility.showSuccess(context, message: 'Meč je uspješno ažuriran!');
      }

      // Clear form and reset state completely
      _clearForm();
      await _loadData();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMatchResult() async {
    if (_selectedMatch == null) return;
    
    // Validate score fields
    if (_homeScoreController.text.isEmpty || _awayScoreController.text.isEmpty) {
      NotificationUtility.showError(context, message: 'Molimo unesite oba rezultata');
      return;
    }
    
    final homeScore = int.tryParse(_homeScoreController.text);
    final awayScore = int.tryParse(_awayScoreController.text);
    
    if (homeScore == null || awayScore == null) {
      NotificationUtility.showError(context, message: 'Rezultati moraju biti valjani brojevi');
      return;
    }

    // Show confirmation dialog
    final confirmed = await DialogUtility.showConfirmation(
      context,
      title: 'Potvrdi ažuriranje rezultata',
      message: 'Da li ste sigurni da želite ažurirati rezultat na ${homeScore} - ${awayScore}?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final matchResult = MatchResult(
        homeGoals: homeScore,
        awayGoals: awayScore,
      );

      await _matchProvider.UpdateMatchResult(_selectedMatch!.id!, matchResult);
      NotificationUtility.showSuccess(context, message: 'Rezultat meča je uspješno ažuriran!');
      
      // Clear form and reset state completely
      _clearForm();
      await _loadData();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška pri ažuriranju rezultata: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteMatch(Match match) async {
    final confirmed = await DialogUtility.showConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati meč protiv ${match.opponentName}?',
    );

    if (confirmed) {
      await _deleteMatch(match);
    }
  }

  Future<void> _deleteMatch(Match match) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _matchProvider.delete(match.id!);
      NotificationUtility.showSuccess(context, message: 'Meč je uspješno obrisan!');
      
      // Clear form and reload data
      _clearForm();
      await _loadData();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška pri brisanju: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMatchDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedMatchDate ?? DateTime.now()),
      );
      if (timePicked != null) {
        setState(() {
          _selectedMatchDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side - Matches list with pagination
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mečevi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                // Add new match button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _clearForm();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj novi meč'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pretraži mečeve...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.blue.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.shade600,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pretraži'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Matches list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _result == null || _result!.data.isEmpty
                          ? const Center(
                              child: Text(
                                'Nema dostupnih mečeva.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _result!.data.length,
                              itemBuilder: (context, index) {
                                final match = _result!.data[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: _selectedMatch?.id == match.id
                                        ? Colors.blue.shade700
                                        : Colors.blue.shade300,
                                      width: _selectedMatch?.id == match.id ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () => _selectMatch(match),
                                    leading: Container(
                                      width: 60,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(match.status),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          match.status ?? 'N/A',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'vs ${match.opponentName ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (match.matchDate != null)
                                          Text(
                                            DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate!),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (match.location != null)
                                          Text(
                                            match.location!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (match.result?.homeGoals != null && match.result?.awayGoals != null)
                                          Text(
                                            'Rezultat: ${match.result!.homeGoals} - ${match.result!.awayGoals}',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: Colors.blue,
                                          tooltip: 'Uredi meč',
                                          onPressed: () => _selectMatch(match),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: Colors.red,
                                          tooltip: 'Obriši meč',
                                          onPressed: () => _confirmDeleteMatch(match),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 16),
                // Pagination controls
                if (_result != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Stavki po stranici: '),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<int>(
                          value: _searchObject.pageSize,
                          underline: const SizedBox(),
                          items: [5, 10, 20, 50]
                              .map((pageSize) => DropdownMenuItem<int>(
                                    value: pageSize,
                                    child: Text(pageSize.toString()),
                                  ))
                              .toList(),
                          onChanged: _changePageSize,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      ElevatedButton(
                        onPressed: _result!.hasPrevious
                            ? () => _changePage((_searchObject.page ?? 0) - 1)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          disabledBackgroundColor: Colors.blue.shade100,
                        ),
                        child: const Text('Prethodna'),
                      ),
                      const SizedBox(width: 16),
                      
                      ..._buildPageNumbers(),
                      
                      const SizedBox(width: 16),
                      
                      ElevatedButton(
                        onPressed: _result!.hasNext
                            ? () => _changePage((_searchObject.page ?? 0) + 1)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          disabledBackgroundColor: Colors.blue.shade100,
                        ),
                        child: const Text('Sljedeća'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // Right side - Form
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(
                color: Colors.blue.shade600,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedMatch == null 
                              ? 'Dodaj novi meč' 
                              : _isFormPopulated() 
                                  ? 'Uredi meč' 
                                  : 'Detalji meča',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedMatch != null && !_isFormPopulated())
                          ElevatedButton.icon(
                            onPressed: () => _populateFormForEditing(),
                            icon: const Icon(Icons.edit),
                            label: const Text('Uredi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Match details (view mode) or form (edit/add mode)
                    if (_selectedMatch != null && !_isFormPopulated()) ...[
                      // View mode - show match details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Protivnik:', _selectedMatch!.opponentName ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Status:', _selectedMatch!.status ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Datum:', _selectedMatch!.matchDate != null 
                                ? DateFormat('dd.MM.yyyy HH:mm').format(_selectedMatch!.matchDate!) 
                                : 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Lokacija:', _selectedMatch!.location ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Opis:', _selectedMatch!.description ?? 'N/A'),
                            if (_selectedMatch!.result != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.emoji_events, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rezultat: ${_selectedMatch!.result!.homeGoals} - ${_selectedMatch!.result!.awayGoals}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // Edit/Add mode - show form fields
                    
                    // Current result display in edit mode
                    if (_selectedMatch?.result != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Trenutni rezultat: ${_selectedMatch!.result!.homeGoals} - ${_selectedMatch!.result!.awayGoals}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Opponent name
                    TextFormField(
                      controller: _opponentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Naziv protivnika',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Molimo unesite naziv protivnika';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Status dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status meča',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Molimo odaberite status meča';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Match date
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Datum i vrijeme meča',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _selectedMatchDate != null
                                ? DateFormat('dd.MM.yyyy HH:mm').format(_selectedMatchDate!)
                                : '',
                          ),
                          validator: (value) {
                            if (_selectedMatchDate == null) {
                              return 'Molimo odaberite datum i vrijeme meča';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokacija',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Molimo unesite lokaciju meča';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Opis',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.trim().isEmpty) {
                          return 'Molimo unesite opis meča';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _clearForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Otkaži'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _selectedMatch == null ? 'Dodaj meč' : 'Sačuvaj izmjene',
                                ),
                        ),
                      ],
                    ),
                    
                    // Result update section
                    if (_selectedMatch != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showResultForm = !_showResultForm;
                              if (_showResultForm) {
                                // Populate result fields with current values
                                _homeScoreController.text = _selectedMatch?.result?.homeGoals?.toString() ?? '';
                                _awayScoreController.text = _selectedMatch?.result?.awayGoals?.toString() ?? '';
                              }
                            });
                          },
                          icon: Icon(_showResultForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          label: Text(_showResultForm ? 'Sakrij rezultat' : 'Ažuriraj rezultat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      // Expandable result form
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _showResultForm ? null : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showResultForm ? 1.0 : 0.0,
                          child: _showResultForm ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ažuriraj rezultat meča',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Current result display (if exists)
                                    if (_selectedMatch?.result != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Trenutni: ${_selectedMatch!.result!.homeGoals} - ${_selectedMatch!.result!.awayGoals}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    
                                    // Score input fields
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _homeScoreController,
                                            decoration: const InputDecoration(
                                              labelText: 'Naš tim',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _awayScoreController,
                                            decoration: InputDecoration(
                                              labelText: _selectedMatch?.opponentName ?? 'Protivnik',
                                              border: const OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Result save button
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _updateMatchResult,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text('Sačuvaj rezultat'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ) : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    ], // Close the else clause for view/edit mode
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Zakazana':
        return Colors.blue;
      case 'Uživo':
        return Colors.green;
      case 'Završena':
        return Colors.grey;
      case 'Otkazana':
        return Colors.red;
      case 'Odložena':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}