import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/providers/comment_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myclub_desktop/models/search_objects/base_search_object.dart';
import 'package:myclub_desktop/providers/news_provider.dart';
import 'package:myclub_desktop/models/news.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';

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
  State<_NewsContent> createState() => _NewsContentState();
}

class _NewsContentState extends State<_NewsContent> {
  late NewsProvider _newsProvider;
  late CommentProvider _commentProvider;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  
  News? _selectedNews;
  PagedResult<News>? _result;
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Multiple images
  List<List<int>> _selectedImagesBytes = [];
  List<String> _selectedImageNames = [];
  List<int> _imagesToKeep = [];
  List<List<int>> _selectedImages = [];

  // Search fields
  BaseSearchObject _searchObject = BaseSearchObject(
    fts: '',
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
    _newsProvider = context.read<NewsProvider>();
    _newsProvider.setContext(context);
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _result = await _newsProvider.get(searchObject: _searchObject);
    } catch (e) {
      print("Error loading news: ${e.toString()}");
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

  Future<void> _loadNewsById(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final news = await _newsProvider.getById(id);
      
      setState(() {
        _selectedNews = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading news details: ${e.toString()}");
    }
  }
  
  void _changePageSize(int? pageSize) {
    if (pageSize != null) {
      _searchObject = BaseSearchObject(
        fts: _searchObject.fts,
        page: 0,
        pageSize: pageSize,
      );
      _loadData();
    }
  }
  
  // Calculate the number of columns based on page size
  int _calculateCrossAxisCount(int pageSize) {
    if (pageSize <= 10) return 2; // 2 columns for 10 or fewer items
    if (pageSize <= 20) return 3; // 3 columns for 11-20 items
    return 4; // 4 columns for more than 20 items
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

      // Show ellipsis if needed
      if (currentPage > 2) {
        pageWidgets.add(const Text('...'));
      }

      // Show current page and neighbors
      for (int i = math.max(1, currentPage - 1); i <= math.min(totalPages - 2, currentPage + 1); i++) {
        pageWidgets.add(_buildPageButton(i));
      }

      // Show ellipsis if needed
      if (currentPage < totalPages - 3) {
        pageWidgets.add(const Text('...'));
      }

      // Always show last page
      pageWidgets.add(_buildPageButton(totalPages - 1));
    }

    return pageWidgets;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == (_searchObject.page ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: isCurrentPage ? Colors.white : Colors.black,
          backgroundColor: isCurrentPage ? Colors.blue : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: isCurrentPage ? null : () => _changePage(page),
        child: Text('${page + 1}'),
      ),
    );
  }
  
  void _selectNews(News news) {
    setState(() {
      _selectedNews = news;
    });
  }
  
  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    _videoUrlController.clear();
    _selectedImagesBytes.clear();
    _selectedImageNames.clear();
    _imagesToKeep.clear();
    
    setState(() {
      _selectedNews = null;
      _isEditing = false;
    });
  }
  
  Future<void> _confirmDeleteNews(News news) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Delete News',
      message: 'Are you sure you want to delete this news article?'
    );

    if (confirm == true) {
      _deleteNews(news);
    }
  }

  Future<void> _deleteNews(News news) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _newsProvider.delete(news.id);
      _clearForm();
      _loadData();
      NotificationUtility.showSuccess(
        context, 
        message: 'News deleted successfully'
      );
    } catch (e) {
      NotificationUtility.showError(
        context, 
        message: 'Error deleting news: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
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
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImagesBytes.length) {
        _selectedImagesBytes.removeAt(index);
        _selectedImageNames.removeAt(index);
      }
    });
  }
  
  Future<void> _saveNews() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newsData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'videoUrl': _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
      };

      if (_selectedNews == null) {
        // Create new news
        await _newsProvider.createNewsWithImages(
          newsData,
          _selectedImagesBytes,
          _selectedImageNames,
        );
        NotificationUtility.showSuccess(
          context, 
          message: 'News created successfully'
        );
      } else {
        // Update existing news
        await _newsProvider.updateNewsWithImages(
          _selectedNews!.id,
          newsData,
          _selectedImagesBytes,
          _selectedImageNames,
          _imagesToKeep,
        );
        NotificationUtility.showSuccess(
          context, 
          message: 'News updated successfully'
        );
      }

      _clearForm();
      _loadData();
    } catch (e) {
      NotificationUtility.showError(
        context, 
        message: 'Error saving news: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }
  
  Widget _buildNewsForm() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedNews == null ? 'Create News' : 'Edit News',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Form fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter news title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Content
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Enter news content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Video URL
                    const Text(
                      'Video URL (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        hintText: 'Enter video URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Images
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // TODO: Implement file picker for images
                            // This would typically use file_picker package
                            // FilePickerResult? result = await FilePicker.platform.pickFiles(
                            //   type: FileType.image,
                            //   allowMultiple: true,
                            // );
                            
                            // if (result != null) {
                            //   setState(() {
                            //     for (var file in result.files) {
                            //       _selectedImageNames.add(file.name);
                            //       _selectedImages.add(file.bytes!);
                            //     }
                            //   });
                            // }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Select Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Display selected image names
                    if (_selectedImageNames.isNotEmpty) ...[
                      const Text(
                        'Selected Images:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: _selectedImageNames
                            .asMap()
                            .entries
                            .map(
                              (entry) => Chip(
                                label: Text(entry.value),
                                onDeleted: () {
                                  setState(() {
                                    _selectedImageNames.removeAt(entry.key);
                                    _selectedImages.removeAt(entry.key);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    
                    // Existing images to keep (for edit mode)
                    if (_selectedNews != null && _selectedNews!.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Current Images:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: _selectedNews!.images
                            .where((img) => img.id != null)
                            .map(
                              (img) => FilterChip(
                                label: Text('Image ${img.id}'),
                                selected: _imagesToKeep.contains(img.id),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _imagesToKeep.add(img.id!);
                                    } else {
                                      _imagesToKeep.remove(img.id);
                                    }
                                  });
                                },
                                avatar: img.imageUrl != null
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(img.imageUrl!),
                                        radius: 12,
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (_titleController.text.trim().isEmpty ||
                        _contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                        ),
                      );
                      return;
                    }
                    
                    final request = {
                      'title': _titleController.text.trim(),
                      'content': _contentController.text.trim(),
                      'videoUrl': _videoUrlController.text.trim(),
                    };
                    
                    try {
                      if (_selectedNews == null) {
                        // Create new news
                        if (_selectedImages.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one image'),
                            ),
                          );
                          return;
                        }
                        
                        await _newsProvider.createNewsWithImages(
                          request,
                          _selectedImages,
                          _selectedImageNames,
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('News created successfully'),
                          ),
                        );
                      } else {
                        // Update existing news
                        await _newsProvider.updateNewsWithImages(
                          _selectedNews!.id,
                          request,
                          _selectedImages.isNotEmpty ? _selectedImages : null,
                          _selectedImageNames.isNotEmpty ? _selectedImageNames : null,
                          _imagesToKeep,
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('News updated successfully'),
                          ),
                        );
                      }
                      
                      // Reset form
                      setState(() {
                        _isEditing = false;
                        _titleController.clear();
                        _contentController.clear();
                        _videoUrlController.clear();
                        _selectedImages.clear();
                        _selectedImageNames.clear();
                        _imagesToKeep.clear();
                      });
                      
                      // Refresh news list
                      await _newsProvider.get();
                      
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_selectedNews == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final news = _result?.data ?? [];
    // Use the local _selectedNews variable instead of provider state
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading && news.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left section - News list with pagination
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'News',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search news...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchController.clear();
                              _search();
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onSubmitted: (value) {
                          _searchController.text = value;
                          _search();
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: news.length,
                          itemBuilder: (context, index) {
                            final item = news[index];
                            final isSelected = _selectedNews?.id == item.id;
                            
                            return InkWell(
                              onTap: () {
                                _loadNewsById(item.id);
                              },
                              child: Card(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primaryContainer 
                                    : null,
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.primaryImage != null && item.primaryImage!.imageUrl != null)
                                      Expanded(
                                        child: Image.network(
                                          item.primaryImage!.imageUrl!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.image),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd.MM.yyyy').format(item.date),
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
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
                            TextButton(
                              onPressed: (_searchObject.page ?? 0) > 0
                                  ? () => _changePage((_searchObject.page ?? 0) - 1)
                                  : null,
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_back),
                                  SizedBox(width: 4),
                                  Text('Previous'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Page ${(_searchObject.page ?? 0) + 1} of ${_result?.totalPages ?? 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: (_searchObject.page ?? 0) < (_result?.totalPages ?? 1) - 1
                                  ? () => _changePage((_searchObject.page ?? 0) + 1)
                                  : null,
                              child: const Row(
                              children: [
                                Text('Next'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Middle section - Comments
                if (_selectedNews != null)
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _selectedNews!.comments.isEmpty
                                  ? const Center(
                                      child: Text('No comments yet'),
                                    )
                                  : ListView.separated(
                                      itemCount: _selectedNews!.comments.length,
                                      separatorBuilder: (context, index) => const Divider(),
                                      itemBuilder: (context, index) {
                                        final comment = _selectedNews!.comments[index];
                                        return ListTile(
                                          title: Text(comment.username ?? 'Anonymous'),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(comment.content ?? ''),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.createdAt != null
                                                    ? DateFormat('dd.MM.yyyy HH:mm')
                                                        .format(comment.createdAt!)
                                                    : '',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          leading: CircleAvatar(
                                            child: Text(
                                              (comment.username != null && comment.username!.isNotEmpty) 
                                                  ? comment.username![0].toUpperCase()
                                                  : 'A',
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
                  )
                else if (_isLoading)
                  const Expanded(
                    flex: 2,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  const Expanded(
                    flex: 2,
                    child: Center(
                      child: Text('Select a news article to view comments'),
                    ),
                  ),
                
                const SizedBox(width: 16),
                
                // Right section - News details/edit form
                Expanded(
                  flex: 3,
                  child: _isEditing
                      ? _buildNewsForm()
                      : _selectedNews != null
                          ? Card(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Admin actions bar
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Edit News',
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                                _titleController.text = _selectedNews!.title;
                                                _contentController.text = _selectedNews!.content;
                                                _videoUrlController.text = _selectedNews!.videoUrl ?? '';
                                                
                                                // Save image IDs to keep
                                                _imagesToKeep = _selectedNews!.images
                                                    .where((img) => img.id != null)
                                                    .map((img) => img.id!)
                                                    .toList();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // News images carousel
                                    if (_selectedNews!.images.isNotEmpty)
                                      SizedBox(
                                        height: 200,
                                        child: PageView.builder(
                                          itemCount: _selectedNews!.images.length,
                                          itemBuilder: (context, index) {
                                            return Image.network(
                                              _selectedNews!.images[index].imageUrl ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(Icons.image_not_supported),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image),
                                        ),
                                      ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // News title
                                          Text(
                                            _selectedNews!.title,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          
                                          // News subtitle
                                          const SizedBox(height: 8),
                                          Text(
                                            'Posted on ${DateFormat('dd.MM.yyyy').format(_selectedNews!.date)} by ${_selectedNews!.username}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          
                                          // News content
                                          const SizedBox(height: 16),
                                          Text(_selectedNews!.content),
                                          
                                          // Video URL
                                          if (_selectedNews!.videoUrl != null &&
                                              _selectedNews!.videoUrl!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Video',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  InkWell(
                                                    onTap: () {
                                                      // TODO: Open video URL or embed video player
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.video_library),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Watch video',
                                                          style: TextStyle(
                                                            color: Colors.blue[700],
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          // Add comment form
                                          const SizedBox(height: 32),
                                          const Text(
                                            'Add a comment',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _commentController,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText: 'Write your comment here...',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (_commentController.text.trim().isNotEmpty) {
                                                  await newsProvider.addComment(
                                                    _selectedNews!.id,
                                                    _commentController.text.trim(),
                                                  );
                                                  _commentController.clear();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Add Comment'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Select a news article to view details or create a new one',
                                      style: TextStyle(fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                          _titleController.clear();
                                          _contentController.clear();
                                          _videoUrlController.clear();
                                          _selectedImages.clear();
                                          _selectedImageNames.clear();
                                          _imagesToKeep.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create New News'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
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
