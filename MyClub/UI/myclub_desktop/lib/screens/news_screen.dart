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

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  // Search fields
  BaseSearchObject _searchObject = BaseSearchObject(
    page: 0,
    pageSize: 10,
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
          backgroundColor: isCurrentPage ? Theme.of(context).primaryColor : null,
          foregroundColor: isCurrentPage ? Colors.white : null,
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

      // Populate image IDs to keep for editing
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

    // Collect all validation errors to show them all at once
    List<String> validationErrors = [];
    
    // Check form fields for completeness
    if (_titleController.text.trim().isEmpty) {
      validationErrors.add('Molimo unesite naslov vijesti');
    }
    
    if (_contentController.text.trim().isEmpty) {
      validationErrors.add('Molimo unesite sadržaj vijesti');
    }
    
    // Check if images are selected for new news
    if (_selectedNews == null && _selectedImagesBytes.isEmpty) {
      validationErrors.add('Molimo odaberite barem jednu sliku za vijest');
    }
    
    // Check if edited news will have any images after removing
    if (_selectedNews != null && _imagesToKeep.isEmpty && _selectedImagesBytes.isEmpty) {
      validationErrors.add('Vijest mora imati barem jednu sliku');
    }
    
    // If there are validation errors, show them all at once
    if (validationErrors.isNotEmpty) {
      NotificationUtility.showError(
        context,
        message: validationErrors.join('\n'),
      );
      return;
    }
    
    // If form validation failed but we didn't catch specific errors above
    if (!isFormValid) {
      NotificationUtility.showError(
        context,
        message: 'Molimo provjerite unesene podatke i pokušajte ponovo.',
      );
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
                  // Search and filter row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Pretraži vijesti',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _search,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Nova vijest'),
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: (_searchObject.page ?? 0) > 0
                                ? () => _changePage((_searchObject.page ?? 0) - 1)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _searchObject.pageSize,
                            items: [10, 20, 50].map((size) {
                              return DropdownMenuItem<int>(
                                value: size,
                                child: Text('$size po stranici'),
                              );
                            }).toList(),
                            onChanged: _changePageSize,
                          ),
                          const SizedBox(width: 16),
                          ..._buildPageNumbers(),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: (_searchObject.page ?? 0) < (_result!.totalPages - 1)
                                ? () => _changePage((_searchObject.page ?? 0) + 1)
                                : null,
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
                border: Border.symmetric(
                  vertical: BorderSide(color: Colors.grey.shade300),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedNews == null ? 'Dodaj novu vijest' : 'Uredi vijest',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Naslov*',
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Content field
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Sadržaj*',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sadržaj je obavezan';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Images section
                    Text(
                      'Slike',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Show existing images if editing
                    if (_selectedNews != null && _selectedNews!.images.isNotEmpty)
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedNews!.images.length,
                          itemBuilder: (context, index) {
                            final image = _selectedNews!.images[index];
                            final shouldKeep = image.id != null && _imagesToKeep.contains(image.id);
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: shouldKeep ? Colors.green : Colors.red,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: image.imageUrl != null
                                      ? Image.network(
                                          image.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.image_not_supported),
                                            );
                                          },
                                        )
                                      : const Center(
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(
                                        shouldKeep ? Icons.check_circle : Icons.remove_circle,
                                        color: shouldKeep ? Colors.green : Colors.red,
                                      ),
                                      onPressed: () {
                                        if (image.id != null) {
                                          setState(() {
                                            if (shouldKeep) {
                                              _imagesToKeep.remove(image.id);
                                            } else {
                                              _imagesToKeep.add(image.id!);
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Show newly selected images
                    if (_selectedImagesBytes.isNotEmpty)
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImagesBytes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Image.memory(
                                      Uint8List.fromList(_selectedImagesBytes[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.image_not_supported),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Button to add images
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Dodaj slike'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveNews,
                        child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_selectedNews == null ? 'Dodaj vijest' : 'Spremi izmjene'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
