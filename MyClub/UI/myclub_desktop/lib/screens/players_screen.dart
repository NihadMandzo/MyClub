import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/models/player.dart';
import 'package:myclub_desktop/models/search_objects/player_search_object.dart';
import 'package:myclub_desktop/providers/player_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: const _PlayersContent(),
    );
  }
}

class _PlayersContent extends StatefulWidget {
  const _PlayersContent({Key? key}) : super(key: key);

  @override
  _PlayersContentState createState() => _PlayersContentState();
}

class _PlayersContentState extends State<_PlayersContent> {
  late PlayerProvider _playerProvider;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  Player? _selectedPlayer;
  PagedResult<Player>? _result;
  bool _isLoading = false;
  
  // Image upload fields
  List<int>? _selectedImageBytes;
  String? _selectedImageName;
  
  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _biographyController = TextEditingController();
  DateTime? _selectedDate;

  // Search fields
  PlayerSearchObject _searchObject = PlayerSearchObject(
    page: 0,
    pageSize: 10,
  );

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _loadData();
  }

  void _initializeProvider() {
    _playerProvider = context.read<PlayerProvider>();
    _playerProvider.setContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    _positionController.dispose();
    _nationalityController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _result = await _playerProvider.get(searchObject: _searchObject);
    } catch (e) {
      NotificationUtility.showError(
        context, 
        message: 'Error loading players: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search() {
    final searchText = _searchController.text.trim();
    _searchObject = PlayerSearchObject(
      name: searchText.isNotEmpty ? searchText : null,
      fts: searchText.isNotEmpty ? searchText : null, // Also set fts for full-text search
      page: 0,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePage(int newPage) {
    _searchObject = PlayerSearchObject(
      name: _searchObject.name,
      fts: _searchObject.fts,  // Preserve fts search term
      page: newPage,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePageSize(int? pageSize) {
    if (pageSize != null) {
      _searchObject = PlayerSearchObject(
        name: _searchObject.name,
        fts: _searchObject.fts,  // Preserve fts search term
        page: 0, // Reset to first page when changing page size
        pageSize: pageSize,
      );
      _loadData();
    }
  }
  
  // Calculate the number of columns based on page size
  int _calculateCrossAxisCount(int pageSize) {
    if (pageSize <= 10) return 4;     // 4 columns for 10 or fewer items (2 rows x 4 cards)
    if (pageSize <= 20) return 5;     // 5 columns for 11-20 items
    return 6;                         // 6 columns for more than 20 items
  }

  // Build page number buttons for pagination
  List<Widget> _buildPageNumbers() {
    if (_result == null) return [];
    
    final currentPage = (_searchObject.page ?? 0);
    final totalPages = _result!.totalPages;
    final List<Widget> pageWidgets = [];
    
    // Logic to show certain page numbers with ellipsis for long ranges
    // Always show first page, last page, and pages around current
    const int maxDisplayedPages = 5;  // Max number of pages to display
    
    if (totalPages <= maxDisplayedPages) {
      // If total pages is small enough, show all pages
      for (int i = 0; i < totalPages; i++) {
        pageWidgets.add(_buildPageButton(i));
      }
    } else {
      // Always show first page
      pageWidgets.add(_buildPageButton(0));
      
      // Calculate range of pages to show around current page
      int startPage = (currentPage - 1).clamp(1, totalPages - 2);
      int endPage = (currentPage + 1).clamp(2, totalPages - 2);
      
      // Adjust to show up to maxDisplayedPages-2 pages (excluding first and last)
      if (endPage - startPage < maxDisplayedPages - 3) {
        if (startPage == 1) {
          endPage = math.min(maxDisplayedPages - 2, totalPages - 2);
        } else if (endPage == totalPages - 2) {
          startPage = math.max(1, totalPages - maxDisplayedPages + 1);
        }
      }
      
      // Show ellipsis after first page if needed
      if (startPage > 1) {
        pageWidgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        ));
      }
      
      // Add middle page numbers
      for (int i = startPage; i <= endPage; i++) {
        pageWidgets.add(_buildPageButton(i));
      }
      
      // Show ellipsis before last page if needed
      if (endPage < totalPages - 2) {
        pageWidgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        ));
      }
      
      // Always show last page if there's more than one page
      if (totalPages > 1) {
        pageWidgets.add(_buildPageButton(totalPages - 1));
      }
    }
    
    return pageWidgets;
  }
  
  // Build a single page number button
  Widget _buildPageButton(int page) {
    final isCurrentPage = page == (_searchObject.page ?? 0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: isCurrentPage ? null : () => _changePage(page),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPage ? Colors.blue.shade700 : Colors.blue.shade200,
          foregroundColor: Colors.white,
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isCurrentPage ? Colors.blue.shade900 : Colors.transparent, 
              width: isCurrentPage ? 2 : 0,
            ),
          ),
        ),
        child: Text('${page + 1}'),
      ),
    );
  }

  void _selectPlayer(Player player) {
    setState(() {
      _selectedPlayer = player;
      _firstNameController.text = player.fullName?.split(' ')[0] ?? '';
      _lastNameController.text = player.fullName?.split(' ').skip(1).join(' ') ?? '';
      _numberController.text = player.number?.toString() ?? '';
      _positionController.text = player.position ?? '';
      _nationalityController.text = player.nationality ?? '';
      _heightController.text = player.height?.toString() ?? '';
      _weightController.text = player.weight?.toString() ?? '';
      _biographyController.text = player.biography ?? '';
      _selectedDate = player.dateOfBirth;
    });
  }

  void _clearForm() {
    setState(() {
      _selectedPlayer = null;
      _firstNameController.clear();
      _lastNameController.clear();
      _numberController.clear();
      _positionController.clear();
      _nationalityController.clear();
      _heightController.clear();
      _weightController.clear();
      _biographyController.clear();
      _selectedDate = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }
  
  // Add delete player functionality
  Future<void> _confirmDeletePlayer(Player player) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite da obrišete ${player.fullName}?',
    );
    
    if (confirm) {
      _deletePlayer(player);
    }
  }
  
  Future<void> _deletePlayer(Player player) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call API to delete player
      // This is a placeholder - you'll need to implement the delete method in your provider
      await _playerProvider.delete(player.id!);

      NotificationUtility.showSuccess(
        context,
        message: 'Igrač uspešno obrisan',
      );
      
      if (_selectedPlayer?.id == player.id) {
        _clearForm();
      }
      
      _loadData();
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška prilikom brisanja igrača: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Use file_picker to select real images
  Future<void> _pickImage() async {
    try {
      // Fallback method since we can't use file_picker directly
      final result = await DialogUtility.showCustomDialog<Map<String, dynamic>>(
        context: context,
        title: 'Upload slike',
        content: const Text(
          'Funkcionalnost za biranje datoteka nije dostupna.\n\n'
          'U stvarnoj implementaciji, ovo bi otvorilo dijalog za odabir datoteke sa slikom.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () {
              // Create a valid PNG image data with a blue square
              // This is a minimal valid PNG file with a 1x1 blue pixel
              List<int> pngBytes = [
                0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
                0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
                0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
                0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
              ];
              
              Navigator.of(context).pop({
                'bytes': pngBytes, 
                'name': 'player_image.png'
              });
            },
            child: const Text('Simulate File Selection'),
          ),
        ],
      );

      if (result != null) {
        setState(() {
          _selectedImageBytes = result['bytes'] as List<int>;
          _selectedImageName = result['name'] as String;

          NotificationUtility.showInfo(
            context,
            message: 'Test slika odabrana',
          );
        });
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška prilikom odabira slike: ${e.toString()}',
      );
    }
  }
  
  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed!');
      // Check if biography is the failing field
      if (_biographyController.text.trim().isEmpty) {
        print('Biography field is empty!');
        NotificationUtility.showError(
          context,
          message: 'Biografija je obavezno polje i ne može biti prazna.',
        );
      }
      return;
    }
    
    // Show error if no image is selected for new players
    if (_selectedPlayer == null && _selectedImageBytes == null) {
      NotificationUtility.showError(
        context,
        message: 'Molimo vas da odaberete sliku za igrača',
      );
      return;
    }

    // Prepare player data without setting loading state
    // Make sure all required fields are included
    final player = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'number': int.parse(_numberController.text.trim()),
      'position': _positionController.text.trim(),
      'nationality': _nationalityController.text.trim(),
      'height': int.tryParse(_heightController.text.trim()) ?? 0,
      'weight': int.tryParse(_weightController.text.trim()) ?? 0,
      'biography': _biographyController.text.trim(),  // Ensure biography is trimmed
      'dateOfBirth': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
    
    // Double check that biography is not empty
    if (player['biography']?.toString().isEmpty ?? true) {
      NotificationUtility.showError(
        context,
        message: 'Biografija je obavezno polje. Molimo vas da unesete biografiju.',
      );
      return;
    }
    
    try {

      if (_selectedPlayer == null) {
        // Check if image is available for new player
        if (_selectedImageBytes == null || _selectedImageName == null) {
          NotificationUtility.showError(
            context,
            message: 'Slika je obavezna za nove igrače',
          );
          // Not loading, just return
          return;
        }
        
        // Show confirmation dialog before adding new player
        final confirmed = await DialogUtility.showConfirmation(
          context,
          title: 'Potvrdi dodavanje',
          message: 'Da li ste sigurni da želite da dodate novog igrača?',
          confirmLabel: 'Potvrdi',
          cancelLabel: 'Otkaži',
        );
        
        if (!confirmed) {
          // Not loading, just return
          return;
        }
        
        // Only set loading state after confirmation
        setState(() {
          _isLoading = true;
        });
        
        // Create new player
        await _playerProvider.insertWithImage(player, _selectedImageBytes, _selectedImageName);
        
        // Reload data to show the new player
        await _loadData();
        
        // Clear the form after successful creation
        _clearForm();
        
        NotificationUtility.showSuccess(
          context,
          message: 'Igrač uspešno kreiran',
        );
      } else {
        // Show confirmation dialog before updating
        final confirmed = await DialogUtility.showConfirmation(
          context,
          title: 'Potvrdi editovanje',
          message: 'Da li ste sigurni da želite da editujete ovog igrača?',
          confirmLabel: 'Potvrdi',
          cancelLabel: 'Otkaži',
        );
        
        if (!confirmed) {
          // Not loading, just return
          return;
        }
        
        // Only set loading state after confirmation
        setState(() {
          _isLoading = true;
        });
        
        // Update existing player
        if (_selectedImageBytes != null && _selectedImageName != null) {
          // Using new image
          await _playerProvider.updateWithImage(_selectedPlayer!.id!, player, _selectedImageBytes, _selectedImageName);
        } else {
          // Make sure to include the existing imageUrl
          if (_selectedPlayer?.imageUrl != null) {
            player['imageUrl'] = _selectedPlayer!.imageUrl as Object;
          }
          // Always use updateWithImage, passing null for imageBytes and fileName
          await _playerProvider.updateWithImage(_selectedPlayer!.id!, player, null, null);
        }
        
        // Reload data to show the updated player
        await _loadData();
        
        // Clear the form after successful update
        _clearForm();
        
        NotificationUtility.showSuccess(
          context,
          message: 'Igrač uspešno ažuriran',
        );
      }

      // No additional cleanup needed here - all handled in success branches
    } catch (e) {
      String errorMessage = 'Greška prilikom čuvanja igrača';

      // Try to parse validation errors
      if (e.toString().contains('validation errors occurred')) {
        errorMessage = 'Please fill in all required fields including image';
      }

      NotificationUtility.showError(
        context,
        message: errorMessage,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side: List and Search
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Igrači i stručni štab',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Pretraži igrače...',
                            prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade300),
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
                        ),
                        child: const Text('Pretraži'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Players list in grid view (4 columns)
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _result == null || _result!.data.isEmpty
                            ? const Center(child: Text('Nema pronađenih igrača'))
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _calculateCrossAxisCount(_searchObject.pageSize ?? 10),
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _result!.data.length,
                                itemBuilder: (context, index) {
                                  final player = _result!.data[index];
                                  return Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: _selectedPlayer?.id == player.id
                                          ? Colors.blue.shade700
                                          : Colors.blue.shade300,
                                        width: _selectedPlayer?.id == player.id ? 2 : 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => _selectPlayer(player),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Player image
                                          Expanded(
                                            flex: 4,
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(10),
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                color: Colors.grey.shade200,
                                                child: player.imageUrl != null
                                                    ? Image.network(
                                                        player.imageUrl!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => 
                                                            const Center(child: Icon(Icons.person, size: 50)),
                                                      )
                                                    : const Center(child: Icon(Icons.person, size: 50)),
                                              ),
                                            ),
                                          ),
                                          // Player name
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: Text(
                                              player.fullName ?? 'Nepoznato',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Action buttons
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.blue),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit, size: 18),
                                                    color: Colors.blue,
                                                    tooltip: 'Edit igrača',
                                                    onPressed: () => _selectPlayer(player),
                                                    constraints: const BoxConstraints(),
                                                    padding: const EdgeInsets.all(4),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.red),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, size: 18),
                                                    color: Colors.red,
                                                    tooltip: 'Obriši igrača',
                                                    onPressed: () => _confirmDeletePlayer(player),
                                                    constraints: const BoxConstraints(),
                                                    padding: const EdgeInsets.all(4),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        // Page size selector - now to the left of the navigation buttons
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
                        
                        // Previous button
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
                        
                        // Page numbers
                        ..._buildPageNumbers(),
                        
                        const SizedBox(width: 16),
                        
                        // Next button
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
          // Right side: Form
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200, // Sivkastija pozadina
                border: Border.all(
                  color: Colors.blue.shade600, // Plavi border
                  width: 2.0, // Debljina bordera
                ),
                borderRadius: BorderRadius.circular(8.0), // Zaobljeni uglovi
              ),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _selectedPlayer == null ? 'Dodaj novog igrača' : 'Edit igrača',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // First row - Image upload (full width)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Slika igrača',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedPlayer == null ? '* Obavezno' : 'Opcionalno',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedPlayer == null ? Colors.red : Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Image container with larger height
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              height: 250, // Good height for full width
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedPlayer == null && _selectedImageBytes == null 
                                      ? Colors.red.withOpacity(0.7) 
                                      : Colors.grey,
                                  width: _selectedPlayer == null && _selectedImageBytes == null ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Display message about drag and drop
                                  if (_selectedImageBytes == null && _selectedPlayer?.imageUrl == null)
                                    const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 50, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Drag & drop sliku ovde ili kliknite za odabir', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  
                                  // Display selected image
                                  if (_selectedImageBytes != null)
                                    Image.memory(
                                      Uint8List.fromList(_selectedImageBytes!),
                                      fit: BoxFit.contain, // Show full image
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.broken_image, size: 40, color: Colors.red),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Greška pri učitavanju slike',
                                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                error.toString(),
                                                style: const TextStyle(fontSize: 10),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                    )
                                  else if (_selectedPlayer?.imageUrl != null)
                                    Image.network(
                                      _selectedPlayer!.imageUrl!,
                                      fit: BoxFit.contain, // Show full image
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.broken_image, size: 40, color: Colors.red),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Greška pri učitavanju slike',
                                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                    ),
                                    
                                  // Show overlay message that drag and drop requires package
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _pickImage,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Drag & drop zahteva flutter_dropzone paket',
                                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Delete button for selected images
                                  if (_selectedImageBytes != null || _selectedPlayer?.imageUrl != null)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImageBytes = null;
                                            _selectedImageName = null;
                                          });
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload sliku'),
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'JPG, PNG, GIF (max 5MB)',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Second row - Player information (two columns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Ime
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ime',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete ime';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Broj dresa
                                TextFormField(
                                  controller: _numberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Broj dresa',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete broj dresa';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Molimo vas da unesete validan broj dresa';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Datum rođenja
                                FormField<DateTime>(
                                  validator: (value) {
                                    if (_selectedDate == null) {
                                      return 'Molimo vas da odaberete datum rođenja';
                                    }
                                    return null;
                                  },
                                  builder: (formFieldState) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            final DateTime? picked = await showDatePicker(
                                              context: context,
                                              initialDate: _selectedDate ?? DateTime.now(),
                                              firstDate: DateTime(1950),
                                              lastDate: DateTime.now(),
                                            );
                                            if (picked != null && picked != _selectedDate) {
                                              setState(() {
                                                _selectedDate = picked;
                                              });
                                              formFieldState.didChange(picked);
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Datum rođenja',
                                              border: const OutlineInputBorder(),
                                              errorText: formFieldState.errorText,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Text(
                                                  _selectedDate == null
                                                      ? 'Odaberite datum'
                                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                                ),
                                                const Icon(Icons.calendar_today),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Visina
                                TextFormField(
                                  controller: _heightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Visina (cm)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete visinu';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Molimo vas da unesete validnu visinu';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Second column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Prezime
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Prezime',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete prezime';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Pozicija
                                TextFormField(
                                  controller: _positionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pozicija',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete poziciju';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Nacionalnost
                                TextFormField(
                                  controller: _nationalityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nacionalnost',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete nacionalnost';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Težina
                                TextFormField(
                                  controller: _weightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Težina (kg)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Molimo vas da unesete težinu';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Molimo vas da unesete validnu težinu';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Biografija - Full width
                      TextFormField(
                        controller: _biographyController,
                        decoration: const InputDecoration(
                          labelText: 'Biografija',
                          border: OutlineInputBorder(),
                          hintText: 'Unesite biografiju igrača',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty || value.trim().isEmpty) {
                            return 'Molimo vas da unesete biografiju';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _clearForm,
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
                            onPressed: _isLoading ? null : _savePlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_selectedPlayer == null ? 'Dodaj igrača' : 'Sačuvaj izmjene'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
