import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myclub_desktop/models/comment.dart';
import 'package:myclub_desktop/models/news.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/models/search_objects/base_search_object.dart';
import 'package:myclub_desktop/providers/news_provider.dart';
import 'package:myclub_desktop/providers/comment_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: const _NewsContent(),
    );
  }
}

class _NewsContent extends StatefulWidget {
  const _NewsContent({Key? key}) : super(key: key);

  @override
  _NewsContentState createState() => _NewsContentState();
}

class _NewsContentState extends State<_NewsContent> {
  late NewsProvider _newsProvider;
  late CommentProvider _commentProvider;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  News? _selectedNews;
  PagedResult<News>? _result;
  bool _isLoading = false;
  
  // Multiple images
  List<List<int>> _selectedImagesBytes = [];
  List<String> _selectedImageNames = [];
  List<int> _imagesToKeep = [];
  bool _showValidationErrors = false;

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  // Search fields
  BaseSearchObject _searchObject = BaseSearchObject(
    page: 0,
    pageSize: 4,
  );

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _loadData();
  }

  // Utility method to handle API errors
  String _formatErrorMessage(dynamic error) {
    // Extract just the error message without the "Exception: " prefix
    String errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring('Exception: '.length);
    }
    
    // Special handling for known error patterns
    if (errorMessage.contains("Cannot delete this")) {
      return errorMessage;
    }
    
    return errorMessage;
  }

  void _initializeProvider() {
    _newsProvider = context.read<NewsProvider>();
    _newsProvider.setContext(context);

    _commentProvider = CommentProvider();
    _commentProvider.setContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching news with search object: ${_searchObject.toJson()}");
      _result = await _newsProvider.get(searchObject: _searchObject);
      print("News fetched: ${_result?.data.length ?? 0} news items found");

      // Debug output for each news item
      if (_result != null && _result!.data.isNotEmpty) {
        for (var news in _result!.data) {
          print("News ID: ${news.id}, Title: ${news.title}");
        }
      } else {
        print("No news found in the result");
      }

    } catch (e) {
      print("Error fetching data: ${e.toString()}");
      NotificationUtility.showError(
        context,
        message: 'Greška u učitavanju vijesti: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search() {
    final searchText = _searchController.text.trim();
    _searchObject = BaseSearchObject(
      fts: searchText.isNotEmpty ? searchText : null,
      page: 0,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePage(int newPage) {
    _searchObject = BaseSearchObject(
      fts: _searchObject.fts,
      page: newPage,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePageSize(int? pageSize) {
    if (pageSize != null) {
      _searchObject = BaseSearchObject(
        fts: _searchObject.fts,
        page: 0, // Reset to first page when changing page size
        pageSize: pageSize,
      );
      _loadData();
    }
  }

  // Calculate the number of columns based on page size
  int _calculateCrossAxisCount() {
    return 2; // Always 2 columns for news grid as per requirements
  }

  // Build page number buttons for pagination
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
      // Always show first page
      pageWidgets.add(_buildPageButton(0));

      int startPage = (currentPage - 1).clamp(1, totalPages - 2);
      int endPage = (currentPage + 1).clamp(2, totalPages - 2);

      if (endPage - startPage < maxDisplayedPages - 3) {
        if (startPage == 1) {
          endPage = math.min(maxDisplayedPages - 2, totalPages - 2);
        } else if (endPage == totalPages - 2) {
          startPage = math.max(1, totalPages - maxDisplayedPages + 2);
        }
      }

      if (startPage > 1) {
        pageWidgets.add(
          Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }

      for (int i = startPage; i <= endPage; i++) {
        pageWidgets.add(_buildPageButton(i));
      }

      if (endPage < totalPages - 2) {
        pageWidgets.add(
          Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _selectNews(News news) async {
    setState(() {
      _isLoading = true;
      _selectedNews = news;
    });

    try {
      // Fetch the detailed news data
      final detailedNews = await _newsProvider.getById(news.id);

      _titleController.text = detailedNews.title;
      _contentController.text = detailedNews.content;
      _videoUrlController.text = detailedNews.videoUrl ?? '';
      
      // Trigger validation to update the form state with the newly set values
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });

      // Reset images
      _selectedImagesBytes = [];
      _selectedImageNames = [];

      // Initialize _imagesToKeep with all image IDs from the news
      _imagesToKeep = [];
      if (detailedNews.images.isNotEmpty) {
        for (var image in detailedNews.images) {
          if (image.id != null) {
            _imagesToKeep.add(image.id!);
          }
        }
      }
      
      // Make sure we have the selected news with all its images
      _selectedNews = detailedNews;
      
      // Reset validation state
      _showValidationErrors = false;
      
      print("News images loaded: ${_selectedNews?.images.length ?? 0}");
      print("Image IDs to keep: $_imagesToKeep");
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška u učitavanju vijesti: ${e.toString()}',
      );
      print("Error in _selectNews: ${e.toString()}");
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
      // Reset news selection
      _selectedNews = null;
      
      // Clear all text controllers
      _titleController.clear();
      _contentController.clear();
      _videoUrlController.clear();
      
      // Reset all image-related variables
      _selectedImagesBytes = [];
      _selectedImageNames = [];
      _imagesToKeep = [];
      
      // Reset validation state
      _showValidationErrors = false;
    });
    
    // Rebuild the UI to ensure all validators are refreshed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // This triggers a rebuild after the frame is done
      });
    });
    
    print("Form has been cleared successfully");
  }

  Future<void> _confirmDeleteNews(News news) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati vijest "${news.title}"?',
    );

    if (confirm) {
      _deleteNews(news);
    }
  }

  Future<void> _deleteNews(News news) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _newsProvider.delete(news.id);

      NotificationUtility.showSuccess(
        context,
        message: 'Vijest uspješno obrisana',
      );

      if (_selectedNews?.id == news.id) {
        _clearForm();
      }

      _loadData();
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška pri brisanju vijesti: ${_formatErrorMessage(e)}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati komentar?',
    );

    if (confirm) {
      _deleteComment(comment);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _commentProvider.delete(comment.id!);

      NotificationUtility.showSuccess(
        context,
        message: 'Komentar uspješno obrisan',
      );

      // Reload selected news to update comments
      if (_selectedNews != null) {
        final updatedNews = await _newsProvider.getById(_selectedNews!.id);
        setState(() {
          _selectedNews = updatedNews;
        });
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška pri brisanju komentara: ${_formatErrorMessage(e)}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.bytes != null) {
              _selectedImagesBytes.add(file.bytes!);
              _selectedImageNames.add(file.name);
            } else if (file.path != null) {
              final bytes = File(file.path!).readAsBytesSync();
              _selectedImagesBytes.add(bytes);
              _selectedImageNames.add(file.name);
            }
          }
        });
        
        print("Selected ${result.files.length} images");
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška pri odabiru slika: ${e.toString()}',
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagesBytes.removeAt(index);
      _selectedImageNames.removeAt(index);
    });
  }
  


  Future<void> _saveNews() async {
    // Trigger full form validation
    final isFormValid = _formKey.currentState!.validate();

    // Set validation state to true to show inline errors
    setState(() {
      _showValidationErrors = true;
    });
    
    // Check form fields and image validation
    bool hasValidationErrors = false;
    
    // Check form fields for completeness
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      hasValidationErrors = true;
    }
    
    // Check if images are selected for new news
    if (_selectedNews == null && _selectedImagesBytes.isEmpty) {
      hasValidationErrors = true;
    }
    
    // Check if edited news will have any images after removing
    if (_selectedNews != null && _imagesToKeep.isEmpty && _selectedImagesBytes.isEmpty) {
      hasValidationErrors = true;
    }
    
    // If validation failed, just return without showing a notification
    if (!isFormValid || hasValidationErrors) {
      return;
    }
    
    // Show confirmation dialog before saving
    final bool confirmSave = await DialogUtility.showConfirmation(
      context,
      title: _selectedNews == null ? 'Potvrdi dodavanje' : 'Potvrdi izmjene',
      message: _selectedNews == null 
          ? 'Da li ste sigurni da želite dodati novu vijest?' 
          : 'Da li ste sigurni da želite sačuvati izmjene vijesti?',
      confirmLabel: 'Da',
      cancelLabel: 'Ne',
    );
    
    if (!confirmSave) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedNews == null) {
        // Create new news
        final newsData = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'videoUrl': _videoUrlController.text.trim(),
        };
        
        // Create new news with images
        await _newsProvider.createNewsWithImages(
          newsData, 
          _selectedImagesBytes,
          _selectedImageNames,
        );
        
        NotificationUtility.showSuccess(
          context,
          message: 'Vijest uspješno dodana',
        );
        
        // Clear the form after successful creation
        _clearForm();
        
        // Refresh the news list
        _loadData();
      } else {
        // Update existing news
        final newsData = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'videoUrl': _videoUrlController.text.trim(),
        };
        
        // Update existing news with images
        await _newsProvider.updateNewsWithImages(
          _selectedNews!.id,
          newsData,
          _selectedImagesBytes.isNotEmpty ? _selectedImagesBytes : null,
          _selectedImageNames.isNotEmpty ? _selectedImageNames : null,
          _imagesToKeep.isNotEmpty ? _imagesToKeep : null,
        );
        
        NotificationUtility.showSuccess(
          context,
          message: 'Vijest uspješno ažurirana',
        );
        
        // Clear the form after successful update
        _clearForm();
        
        // Refresh the news list
        _loadData();
      }
    } catch (e) {
      print('Error saving news: ${e.toString()}');
      
      // Format the error message to make it more user-friendly
      String errorMessage = _formatErrorMessage(e);
      
      NotificationUtility.showError(
        context,
        message: 'Greška pri spremanju vijesti: $errorMessage',
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
          // Left side - News grid
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vijesti',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search and filter row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Pretraži vijesti...',
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
                        ),
                        child: const Text('Pretraži'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // News grid
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_result == null || _result!.data.isEmpty)
                        ? const Center(child: Text('Nema pronađenih vijesti'))
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _calculateCrossAxisCount(),
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _result!.data.length,
                            itemBuilder: (context, index) {
                              final news = _result!.data[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _selectNews(news),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // News image
                                          Expanded(
                                            flex: 3,
                                            child: news.primaryImage != null && news.primaryImage!.imageUrl != null
                                              ? Image.network(
                                                  news.primaryImage!.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(Icons.image_not_supported, size: 40),
                                                    );
                                                  },
                                                )
                                              : const Center(
                                                  child: Icon(Icons.image_not_supported, size: 40),
                                                ),
                                          ),
                                          // News title
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                news.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Delete button
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDeleteNews(news),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Pagination
                  if (_result != null && _result!.totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Page size selector
                          const Text('Stavki po stranici: '),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<int>(
                              value: _searchObject.pageSize,
                              underline: const SizedBox(),
                              items: [4, 6, 8,10]
                                  .map(
                                    (pageSize) => DropdownMenuItem<int>(
                                      value: pageSize,
                                      child: Text(pageSize.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _changePageSize,
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Previous button
                          ElevatedButton(
                            onPressed: (_searchObject.page ?? 0) > 0
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
                            child: const Text('Prethodni'),
                          ),
                          const SizedBox(width: 16),

                          // Page numbers
                          ..._buildPageNumbers(),

                          const SizedBox(width: 16),

                          // Next button
                          ElevatedButton(
                            onPressed: (_searchObject.page ?? 0) < (_result!.totalPages - 1)
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
                            child: const Text('Sljedeći'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Middle section - Comments
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komentari',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _selectedNews == null
                        ? const Center(child: Text('Odaberite vijest za prikaz komentara'))
                        : _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (_selectedNews!.comments.isEmpty)
                            ? const Center(child: Text('Nema komentara za ovu vijest'))
                            : ListView.builder(
                                itemCount: _selectedNews!.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _selectedNews!.comments[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.username ?? 'Anonimni korisnik',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(comment.content ?? ''),
                                              const SizedBox(height: 16), // Space for delete button
                                            ],
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _confirmDeleteComment(comment),
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
              ),
            ),
          ),
          
          // Right side - News form
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.blue.shade600, width: 2.0),
                borderRadius: BorderRadius.circular(8.0),
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
                        _selectedNews == null ? 'Dodaj novu vijest' : 'Uredi vijest',
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
                                'Slike vijesti',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Add new images button
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_photo_alternate, size: 16),
                                label: const Text('Dodaj nove slike'),
                                onPressed: _pickImages,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Show existing images if editing
                          if (_selectedNews != null && _selectedNews!.images.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.photo_library, size: 18, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Postojeće slike vijesti',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Show existing images
                                Container(
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: _selectedNews!.images
                                      .where((image) => image.id == null || _imagesToKeep.contains(image.id))
                                      .isEmpty
                                      ? Container(
                                          height: 120,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Text('Nema slika za prikaz'),
                                          ),
                                        )
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _selectedNews!.images
                                              .where((image) => image.id == null || _imagesToKeep.contains(image.id))
                                              .length,
                                          itemBuilder: (context, index) {
                                            final image = _selectedNews!.images
                                                .where((image) => image.id == null || _imagesToKeep.contains(image.id))
                                                .toList()[index];
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 120,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: image.imageUrl != null
                                                ? Image.network(
                                                    image.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Center(
                                                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                                      );
                                                    },
                                                  )
                                                : const Center(
                                                    child: Icon(Icons.image_not_supported),
                                                  ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: InkWell(
                                                onTap: () {
                                                  // Check if this would remove the last image
                                                  final bool isLastImage = 
                                                      _selectedNews!.images.length == 1 && 
                                                      _selectedImagesBytes.isEmpty;
                                                      
                                                  if (isLastImage) {
                                                    NotificationUtility.showError(
                                                      context, 
                                                      message: 'Ne možete ukloniti zadnju sliku vijesti. Dodajte novu sliku prije uklanjanja postojeće.'
                                                    );
                                                    return;
                                                  }
                                                  
                                                  if (image.id != null) {
                                                    setState(() {
                                                      _imagesToKeep.remove(image.id);
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          
                          // New selected images section header
                          if (_selectedImagesBytes.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.add_photo_alternate, size: 18, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      'Nove slike vijesti',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Selected images preview
                                Container(
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImagesBytes.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 120,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Image.memory(
                                                Uint8List.fromList(_selectedImagesBytes[index]),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                                  );
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: InkWell(
                                                onTap: () => _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
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

                          // If no images at all (neither existing nor new ones)
                          if (_selectedImagesBytes.isEmpty && 
                              (_selectedNews == null || 
                               _selectedNews!.images.isEmpty ||
                               _imagesToKeep.isEmpty))
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _showValidationErrors ? Colors.red : Colors.grey,
                                  width: _showValidationErrors ? 2.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 40,
                                      color: _showValidationErrors ? Colors.red.shade300 : Colors.grey,
                                    ),
                                    Text(
                                      'Nema odabranih slika',
                                      style: TextStyle(
                                        color: _showValidationErrors ? Colors.red.shade300 : Colors.grey,
                                      ),
                                    ),
                                    if (_showValidationErrors)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Obavezno dodajte barem jednu sliku',
                                          style: TextStyle(
                                            color: Colors.red.shade300,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8.0,
                            ),
                            child: Text(
                              'JPG, PNG, JPEG formati su podržani. Maksimalna veličina slike je 5MB.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // News Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Naslov vijesti*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Naslov je obavezan';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Video URL field (optional)
                      TextFormField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL (opcionalno)',
                          border: OutlineInputBorder(),
                          hintText: 'Unesite URL do YouTube ili drugog video sadržaja',
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Content field
                      TextFormField(
                        controller: _contentController,
                        maxLines: 8,
                        minLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Sadržaj vijesti*',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          hintText: 'Unesite sadržaj vijesti',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sadržaj je obavezan';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Form buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _clearForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Otkaži'),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveNews,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
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
                                  _selectedNews == null ? 'Dodaj vijest' : 'Sačuvaj izmjene',
                                ),
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
