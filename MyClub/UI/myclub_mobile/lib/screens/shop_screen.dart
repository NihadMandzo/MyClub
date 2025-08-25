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
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  
  const ShopScreen({Key? key, this.onCartUpdated}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ProductProvider _productProvider;
  late CategoryProvider _categoryProvider;
  late ColorProvider _colorProvider;
  late SizeProvider _sizeProvider;

  List<ProductResponse> _products = [];
  List<ProductResponse> _recommendedProducts = [];
  List<CategoryResponse> _categories = [];
  List<ColorResponse> _colors = [];
  List<SizeResponse> _sizes = [];

  bool _isLoading = false;
  bool _isRecommendedLoading = false;
  bool _isSearchBarOpen = false;

  // Pagination variables
  int _currentPage = 0;
  int _pageSize = 10; // Changed from 6 to 10
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
      await Future.wait([_loadCategories(), _loadColors(), _loadSizes()]);

      // Load products and recommended products
      await Future.wait([_loadProducts(), _loadRecommendedProducts()]);
    } catch (e) {
      NotificationHelper.showApiError(context, e, 'učitavanju proizvoda');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() {
      _isRecommendedLoading = true;
    });

    try {
      final recommendedProducts = await _productProvider.getRecommended();
      setState(() {
        _recommendedProducts = recommendedProducts;
      });
    } catch (e) {
      print('Error loading recommended products: $e');
      // Don't show error for recommended products, just fail silently
    } finally {
      setState(() {
        _isRecommendedLoading = false;
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
      NotificationHelper.showApiError(context, e, 'učitavanju proizvoda');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Container(
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                            setModalState(() {
                              _priceRange = values;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Categories
                        const Text(
                          'Kategorije',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategoryIds.contains(
                              category.id,
                            );
                            return FilterChip(
                              label: Text(
                                category.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade700,
                              backgroundColor: Colors.grey.shade100,
                              checkmarkColor: Colors.white,
                              elevation: isSelected ? 3 : 1,
                              pressElevation: 4,
                              onSelected: (selected) {
                                setModalState(() {
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _colors.map((color) {
                            final isSelected = _selectedColorIds.contains(
                              color.id,
                            );
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
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    color.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade700,
                              backgroundColor: Colors.grey.shade100,
                              checkmarkColor: Colors.white,
                              elevation: isSelected ? 3 : 1,
                              pressElevation: 4,
                              onSelected: (selected) {
                                setModalState(() {
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _sizes.map((size) {
                            final isSelected = _selectedSizeIds.contains(
                              size.id,
                            );
                            return FilterChip(
                              label: Text(
                                size.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade700,
                              backgroundColor: Colors.grey.shade100,
                              checkmarkColor: Colors.white,
                              elevation: isSelected ? 3 : 1,
                              pressElevation: 4,
                              onSelected: (selected) {
                                setModalState(() {
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
                  padding: const EdgeInsets.all(5),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSearchBarOpen && _searchQuery.isNotEmpty
              ? 'Rezultati pretrage'
              : 'Prodavnica',
          style: TextStyle(
            fontSize: ResponsiveHelper.titleSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recommended products section
                        if (_recommendedProducts.isNotEmpty && !_isSearchBarOpen)
                          _buildRecommendedSection(),
                        
                        // Main products section
                        _products.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'Nema proizvoda za prikaz',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Proizvodi',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  // Products grid
                                  GridView.builder(
                                    padding: ResponsiveHelper.pagePadding(context),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              ResponsiveHelper.gridCrossAxisCount(
                                                context,
                                              ),
                                          childAspectRatio:
                                              ResponsiveHelper.gridChildAspectRatio(
                                                context,
                                              ),
                                          crossAxisSpacing: ResponsiveHelper.gridSpacing(
                                            context,
                                          ),
                                          mainAxisSpacing: ResponsiveHelper.gridSpacing(
                                            context,
                                          ),
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
                                        isLoading: _isLoading,
                                        showPageNumbers: true,
                                        showPageSizeSelector:
                                            false, // Disabled page size selector
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
    );
  }

  Widget _buildRecommendedSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.productCardSpacing(context, base: 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: ResponsiveHelper.pagePadding(context).copyWith(
              top: 0,
              bottom: 0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.recommend,
                  color: Colors.blue.shade700,
                  size: ResponsiveHelper.iconSize(context),
                ),
                SizedBox(width: ResponsiveHelper.productCardSpacing(context, base: 8)),
                Text(
                  'Preporučeno za tebe',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.titleSize(context),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.productCardSpacing(context, base: 12)),
          if (_isRecommendedLoading)
            Container(
              height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 160 : 180,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Container(
              height: ResponsiveHelper.recommendedCardHeight(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: ResponsiveHelper.pagePadding(context).copyWith(
                  top: 0,
                  bottom: 0,
                ),
                itemCount: _recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = _recommendedProducts[index];
                  return Container(
                    width: ResponsiveHelper.recommendedCardWidth(context),
                    margin: EdgeInsets.only(
                      right: ResponsiveHelper.productCardSpacing(context, base: 12),
                    ),
                    child: _buildRecommendedProductCard(product),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProductCard(ProductResponse product) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.productCardSpacing(context, base: 12)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                onCartUpdated: widget.onCartUpdated,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.productCardSpacing(context, base: 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveHelper.productCardSpacing(context, base: 12)),
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveHelper.productCardSpacing(context, base: 12)),
                  ),
                  child: product.primaryImageUrl.imageUrl.isNotEmpty
                      ? Image.network(
                          product.primaryImageUrl.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.image_not_supported,
                                size: ResponsiveHelper.iconSize(context) * 1.5,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.image,
                            size: ResponsiveHelper.iconSize(context) * 1.5,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: ResponsiveHelper.productCardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name and category section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.productTitleSize(context) * 0.85, // Slightly smaller for recommended
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Small spacing between name and category
                        SizedBox(height: ResponsiveHelper.productCardSpacing(context, base: 1)),
                        // Category name
                        Text(
                          product.category.name,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.productSubtitleSize(context) * 0.85,
                            color: Colors.grey.shade600,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Price section
                    Text(
                      '${product.price.toStringAsFixed(2)} KM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.productPriceSize(context) * 0.85,
                        color: Colors.blue,
                        height: 1.0,
                      ),
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

  Widget _buildProductCard(ProductResponse product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                onCartUpdated: widget.onCartUpdated,
              ),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
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
                padding: ResponsiveHelper.productCardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and category - fixed space allocation
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Product name - takes up to 2 lines
                          Expanded(
                            flex: 2,
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.productTitleSize(context),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Category name - single line
                          Text(
                            product.category.name,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.productSubtitleSize(context),
                              color: Colors.grey.shade600,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Fixed spacing between sections
                    SizedBox(height: ResponsiveHelper.productCardSpacing(context, base: 15)),

                    // Rating and Price section - fixed space allocation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // Price - always at the bottom with consistent spacing
                        Container(
                          width: double.infinity,
                          child: Text(
                            '${product.price.toStringAsFixed(2)} KM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.productPriceSize(context),
                              color: Colors.blue,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Consistent bottom padding
                    SizedBox(height: ResponsiveHelper.productCardSpacing(context, base: 2)),
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
