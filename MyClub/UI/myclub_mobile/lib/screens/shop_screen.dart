import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/responses/product_response.dart';
import '../models/responses/category_response.dart';
import '../models/responses/color_response.dart';
import '../models/responses/size_response.dart';
import '../models/search_objects/product_search_object.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/color_provider.dart';
import '../providers/size_provider.dart';
import '../widgets/pagination_widget.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ProductProvider _productProvider;
  late CategoryProvider _categoryProvider;
  late ColorProvider _colorProvider;
  late SizeProvider _sizeProvider;

  List<ProductResponse> _products = [];
  List<CategoryResponse> _categories = [];
  List<ColorResponse> _colors = [];
  List<SizeResponse> _sizes = [];

  bool _isLoading = false;
  bool _isSearchBarOpen = false;
  
  // Pagination variables
  int _currentPage = 0;
  int _pageSize = 6;
  int _totalPages = 0;
  
  // Filter values
  List<int> _selectedCategoryIds = [];
  List<int> _selectedColorIds = [];
  List<int> _selectedSizeIds = [];
  double _minPrice = 0;
  double _maxPrice = 1000;
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();
    _categoryProvider = context.read<CategoryProvider>();
    _colorProvider = context.read<ColorProvider>();
    _sizeProvider = context.read<SizeProvider>();
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load filter options
      await Future.wait([
        _loadCategories(),
        _loadColors(),
        _loadSizes(),
      ]);

      // Load products
      await _loadProducts();
    } catch (e) {
      _showErrorSnackBar('Greška pri učitavanju podataka: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _categoryProvider.get();
      setState(() {
        _categories = result.result ?? [];
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadColors() async {
    try {
      final result = await _colorProvider.get();
      setState(() {
        _colors = result.result ?? [];
      });
    } catch (e) {
      print('Error loading colors: $e');
    }
  }

  Future<void> _loadSizes() async {
    try {
      final result = await _sizeProvider.get();
      setState(() {
        _sizes = result.result ?? [];
      });
    } catch (e) {
      print('Error loading sizes: $e');
    }
  }

  Future<void> _loadProducts({int? page}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final searchObject = ProductSearchObject(
        fTS: _searchQuery.isEmpty ? null : _searchQuery,
        categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
        colorIds: _selectedColorIds.isEmpty ? null : _selectedColorIds,
        sizeIds: _selectedSizeIds.isEmpty ? null : _selectedSizeIds,
        minPrice: _priceRange.start == _minPrice ? null : _priceRange.start,
        maxPrice: _priceRange.end == _maxPrice ? null : _priceRange.end,
        page: page ?? _currentPage,
        pageSize: _pageSize,
        retrieveAll: false, // Ensure pagination is used
      );

      final result = await _productProvider.get(searchObject: searchObject);
      setState(() {
        _products = result.result ?? [];
        _currentPage = result.currentPage ?? 0;
        _totalPages = result.totalPages ?? 0;
      });
    } catch (e) {
      _showErrorSnackBar('Greška pri učitavanju proizvoda: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0; // Reset to first page when applying filters
    });
    _loadProducts();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadProducts(page: page);
  }

  void _onPageSizeChanged(int newPageSize) {
    setState(() {
      _pageSize = newPageSize;
      _currentPage = 0; // Reset to first page when changing page size
    });
    _loadProducts();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _selectedColorIds.clear();
      _selectedSizeIds.clear();
      _priceRange = RangeValues(_minPrice, _maxPrice);
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 0; // Reset to first page when clearing filters
    });
    _loadProducts();
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchBarOpen = !_isSearchBarOpen;
      if (!_isSearchBarOpen) {
        // Clear search when closing
        _searchQuery = '';
        _searchController.clear();
        _currentPage = 0;
        _loadProducts();
      }
    });
  }

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filteri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price range slider
                      const Text(
                        'Cena',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _priceRange,
                        min: _minPrice,
                        max: _maxPrice,
                        divisions: 100,
                        labels: RangeLabels(
                          '${_priceRange.start.round()} KM',
                          '${_priceRange.end.round()} KM',
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Categories
                      const Text(
                        'Kategorije',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryIds.contains(category.id);
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(category.id);
                                } else {
                                  _selectedCategoryIds.remove(category.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Colors
                      const Text(
                        'Boje',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _colors.map((color) {
                          final isSelected = _selectedColorIds.contains(color.id);
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _parseColor(color.hexCode),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(color.name),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedColorIds.add(color.id);
                                } else {
                                  _selectedColorIds.remove(color.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sizes
                      const Text(
                        'Veličine',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _sizes.map((size) {
                          final isSelected = _selectedSizeIds.contains(size.id);
                          return FilterChip(
                            label: Text(size.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSizeIds.add(size.id);
                                } else {
                                  _selectedSizeIds.remove(size.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Otkazi'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Primeni'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSearchBarOpen && _searchQuery.isNotEmpty 
            ? 'Rezultati pretrage' 
            : 'Prodavnica'),
        backgroundColor: const Color.fromARGB(255, 47, 136, 225),
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearchBarOpen ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar - only show when open
          if (_isSearchBarOpen)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color.fromARGB(255, 47, 136, 225),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Pretraži proizvode...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _loadProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _currentPage = 0; // Reset to first page when searching
                  });
                  _loadProducts();
                },
              ),
            ),
          // Products grid with pagination
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(
                        child: Text(
                          'Nema proizvoda za prikaz',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Products grid
                            GridView.builder(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return _buildProductCard(product);
                              },
                            ),
                            
                            // Pagination at the end of the list
                            if (_totalPages > 1)
                              Container(
                                margin: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: PaginationWidget(
                                  currentPage: _currentPage,
                                  totalPages: _totalPages,
                                  currentPageSize: _pageSize,
                                  onPageChanged: _onPageChanged,
                                  onPageSizeChanged: _onPageSizeChanged,
                                  isLoading: _isLoading,
                                  showPageNumbers: true,
                                  showPageSizeSelector: true,
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductResponse product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    color: Colors.white,
                    child: product.primaryImageUrl.imageUrl.isNotEmpty
                        ? Image.network(
                            product.primaryImageUrl.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.white,
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating
                        if (product.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        
                        // Price
                        Text(
                          '${product.price.toStringAsFixed(2)} KM',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
