import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myclub_desktop/utilities/category_dialog.dart';
import 'package:myclub_desktop/utilities/color_dialog.dart';
import 'package:myclub_desktop/utilities/size_dialog.dart';
import 'package:myclub_desktop/models/category.dart';
import 'package:myclub_desktop/models/color.dart' as model;
import 'package:myclub_desktop/models/size.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/models/product.dart';
import 'package:myclub_desktop/models/product_size.dart';
import 'package:myclub_desktop/models/search_objects/product_search_object.dart';
import 'package:myclub_desktop/providers/category_provider.dart';
import 'package:myclub_desktop/providers/color_provider.dart';
import 'package:myclub_desktop/providers/product_provider.dart';
import 'package:myclub_desktop/providers/size_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: const _ShopContent(),
    );
  }
}

class _ShopContent extends StatefulWidget {
  const _ShopContent({Key? key}) : super(key: key);

  @override
  _ShopContentState createState() => _ShopContentState();
}

class _ShopContentState extends State<_ShopContent> {
  late ProductProvider _productProvider;
  late CategoryProvider _categoryProvider;
  late ColorProvider _colorProvider;
  late SizeProvider _sizeProvider;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Product? _selectedProduct;
  PagedResult<Product>? _result;
  bool _isLoading = false;

  // Multiple images
  List<List<int>> _selectedImagesBytes = [];
  List<String> _selectedImageNames = [];
  List<int> _imagesToKeep = [];

  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Dropdown fields
  int? _selectedColorId;
  int? _selectedCategoryId;
  bool _isActive = true;

  // Product sizes
  List<ProductSize> _productSizes = [];

  // Data from API
  List<Category> _categories = [];
  List<model.Color> _colors = [];
  List<Size> _sizes = [];

  // Search fields
  ProductSearchObject _searchObject = ProductSearchObject(
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
    _productProvider = context.read<ProductProvider>();
    _productProvider.setContext(context);

    _categoryProvider = CategoryProvider();
    _categoryProvider.setContext(context);

    _colorProvider = ColorProvider();
    _colorProvider.setContext(context);

    _sizeProvider = SizeProvider();
    _sizeProvider.setContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching products with search object: ${_searchObject.toJson()}");
      _result = await _productProvider.get(searchObject: _searchObject);
      print("Products fetched: ${_result?.data.length ?? 0} products found");

      // Debug output for each product
      if (_result != null && _result!.data.isNotEmpty) {
        for (var product in _result!.data) {
          print(
            "Product: ${product.name}, ID: ${product.id}, ImageUrl: ${product.primaryImageUrl}",
          );
        }
      } else {
        print("No products found in the result");
      }

      // Fetch categories, colors, and sizes
      var categoriesResult = await _categoryProvider.get();
      _categories = categoriesResult.data;

      var colorsResult = await _colorProvider.get();
      _colors = colorsResult.data;

      var sizesResult = await _sizeProvider.get();
      _sizes = sizesResult.data;

      print("Categories fetched: ${_categories.length}");
      print("Colors fetched: ${_colors.length}");
      print("Sizes fetched: ${_sizes.length}");
    } catch (e) {
      print("Error fetching data: ${e.toString()}");
      NotificationUtility.showError(
        context,
        message: 'Greška u učitavanju proizvoda: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search() {
    final searchText = _searchController.text.trim();
    _searchObject = ProductSearchObject(
      name: searchText.isNotEmpty ? searchText : null,
      fts: searchText.isNotEmpty ? searchText : null,
      page: 0,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePage(int newPage) {
    _searchObject = ProductSearchObject(
      name: _searchObject.name,
      fts: _searchObject.fts,
      categoryId: _searchObject.categoryId,
      colorId: _searchObject.colorId,
      minPrice: _searchObject.minPrice,
      maxPrice: _searchObject.maxPrice,
      isActive: _searchObject.isActive,
      page: newPage,
      pageSize: _searchObject.pageSize,
    );
    _loadData();
  }

  void _changePageSize(int? pageSize) {
    if (pageSize != null) {
      _searchObject = ProductSearchObject(
        name: _searchObject.name,
        fts: _searchObject.fts,
        categoryId: _searchObject.categoryId,
        colorId: _searchObject.colorId,
        minPrice: _searchObject.minPrice,
        maxPrice: _searchObject.maxPrice,
        isActive: _searchObject.isActive,
        page: 0, // Reset to first page when changing page size
        pageSize: pageSize,
      );
      _loadData();
    }
  }

  // Calculate the number of columns based on page size
  int _calculateCrossAxisCount(int pageSize) {
    if (pageSize <= 10) return 4; // 4 columns for 10 or fewer items
    if (pageSize <= 20) return 5; // 5 columns for 11-20 items
    return 6; // 6 columns for more than 20 items
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
          startPage = math.max(1, totalPages - maxDisplayedPages + 1);
        }
      }

      if (startPage > 1) {
        pageWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }

      for (int i = startPage; i <= endPage; i++) {
        pageWidgets.add(_buildPageButton(i));
      }

      if (endPage < totalPages - 2) {
        pageWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
          backgroundColor: isCurrentPage
              ? Colors.blue.shade700
              : Colors.blue.shade200,
          foregroundColor: Colors.white,
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

  void _selectProduct(Product product) async {
    setState(() {
      _isLoading = true;
      _selectedProduct = product;
    });

    try {
      // Fetch the detailed product data
      final detailedProduct = await _productProvider.getById(product.id!);

      _nameController.text = detailedProduct.name ?? '';
      _descriptionController.text = detailedProduct.description ?? '';
      _barcodeController.text = detailedProduct.barCode ?? '';
      _priceController.text = detailedProduct.price?.toString() ?? '';
      _selectedColorId = detailedProduct.color?.id;
      _selectedCategoryId = detailedProduct.category?.id;
      _isActive = detailedProduct.isActive ?? true;

      // Reset images
      _selectedImagesBytes = [];
      _selectedImageNames = [];

      // Debug the API response to verify what we're receiving
      print("API response for sizes: ${detailedProduct.sizes}");

      // Populate product sizes from API
      _productSizes = [];
      if (detailedProduct.sizes != null && detailedProduct.sizes!.isNotEmpty) {
        for (var sizeData in detailedProduct.sizes!) {
          // Debug each size to verify id and name
          print(
            "Processing size - ID: ${sizeData.size?.id}, Name: ${sizeData.size?.name}, Quantity: ${sizeData.quantity}",
          );

          // Create a Size object directly instead of just passing an ID
          Size size = Size(id: sizeData.size?.id, name: sizeData.size?.name);

          // Create the ProductSize with the full Size object
          _productSizes.add(
            ProductSize(size: size, quantity: sizeData.quantity),
          );
        }
      }

      // Populate image IDs to keep for editing
      _imagesToKeep = [];
      if (detailedProduct.imageUrls != null &&
          detailedProduct.imageUrls!.isNotEmpty) {
        for (var image in detailedProduct.imageUrls!) {
          if (image.id != null) {
            _imagesToKeep.add(image.id!);
          }
        }
      }

      print(
        "Loaded ${_productSizes.length} sizes for product ${detailedProduct.name}",
      );
      for (var size in _productSizes) {
        print(
          "Size ID: ${size.size?.id}, Name: ${size.size?.name}, Quantity: ${size.quantity}",
        );
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Error loading product details: ${e.toString()}',
      );
      print("Error in _selectProduct: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedProduct = null;
      _nameController.clear();
      _descriptionController.clear();
      _barcodeController.clear();
      _priceController.clear();
      _selectedColorId = null;
      _selectedCategoryId = null;
      _isActive = true;

      // Reset images
      _selectedImagesBytes = [];
      _selectedImageNames = [];
      _imagesToKeep = [];

      // Reset product sizes
      _productSizes = [];
    });

    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati ${product.name}?',
    );

    if (confirm) {
      _deleteProduct(product);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _productProvider.delete(product.id!);

      NotificationUtility.showSuccess(
        context,
        message: 'Proizvod uspješno obrisan',
      );

      if (_selectedProduct?.id == product.id) {
        _clearForm();
      }

      _loadData();
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška u brisanju proizvoda: ${e.toString()}',
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
        final files = result.files;

        for (var file in files) {
          if (file.bytes != null) {
            // Web platform
            setState(() {
              _selectedImagesBytes.add(file.bytes!);
              _selectedImageNames.add(file.name);
            });
          } else if (file.path != null) {
            // Desktop platforms
            final fileBytes = await File(file.path!).readAsBytes();
            setState(() {
              _selectedImagesBytes.add(fileBytes);
              _selectedImageNames.add(file.name);
            });
          }
        }

        // Validate the form field after images added
        _formKey.currentState?.validate();

        NotificationUtility.showSuccess(
          context,
          message: '${files.length} slike uspješno odabrane',
        );
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška u odabiru slika: ${e.toString()}',
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagesBytes.removeAt(index);
      _selectedImageNames.removeAt(index);
      _formKey.currentState?.validate();
    });
  }

  void _addProductSize() {
    setState(() {
      _productSizes.add(ProductSize.create(sizeId: null, quantity: 0));
    });
  }

  void _updateProductSize(int index, int? sizeId, int? quantity) {
    setState(() {
      _productSizes[index] = ProductSize.create(
        sizeId: sizeId,
        quantity: quantity,
      );
    });
  }

  void _removeProductSize(int index) {
    setState(() {
      _productSizes.removeAt(index);
    });
  }

  // Helper method to convert hex color string to Color
  Color _parseHexColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse('0x$hexCode'));
    } catch (e) {
      return Colors.grey; // Default color if parsing fails
    }
  }

  Future<void> _showAddColorDialog({model.Color? color}) async {
    final isEdit = color != null;
    
    final result = await ColorDialog.show(
      context,
      name: color?.name,
      hexCode: color?.hexCode,
      isEdit: isEdit,
    );
    
    if (result != null) {
      try {
        if (isEdit && color.id != null) {
          await _colorProvider.update(color.id!, result);
        } else {
          await _colorProvider.insert(result);
        }
        
        // Refresh colors list
        var colorsResult = await _colorProvider.get();
        setState(() {
          _colors = colorsResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: isEdit 
            ? 'Boja uspješno izmijenjena' 
            : 'Boja uspješno dodana',
        );
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: isEdit
            ? 'Greška u izmjeni boje: ${e.toString()}'
            : 'Greška u dodavanju boje: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteColor(model.Color color) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati boju "${color.name ?? ''}"?',
    );
    
    if (confirm) {
      try {
        await _colorProvider.delete(color.id!);
        
        // Update selected color if it was deleted
        if (_selectedColorId == color.id) {
          setState(() {
            _selectedColorId = null;
          });
        }
        
        // Refresh colors list
        var colorsResult = await _colorProvider.get();
        setState(() {
          _colors = colorsResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: 'Boja uspješno obrisana',
        );
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: _formatErrorMessage(e),
        );
      }
    }
  }

  Future<void> _showAddCategoryDialog({Category? category}) async {
    final isEdit = category != null;
    
    final result = await CategoryDialog.show(
      context,
      name: category?.name,
      description: category?.description,
      isEdit: isEdit,
    );
    
    if (result != null) {
      try {
        if (isEdit && category.id != null) {
          await _categoryProvider.update(category.id!, result);
        } else {
          await _categoryProvider.insert(result);
        }
        
        // Refresh categories list
        var categoriesResult = await _categoryProvider.get();
        setState(() {
          _categories = categoriesResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: isEdit 
            ? 'Kategorija uspješno izmijenjena' 
            : 'Kategorija uspješno dodana',
        );
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: isEdit
            ? 'Greška u izmjeni kategorije: ${e.toString()}'
            : 'Greška u dodavanju kategorije: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati kategoriju "${category.name ?? ''}"?',
    );
    
    if (confirm) {
      try {
        await _categoryProvider.delete(category.id!);
        
        // Update selected category if it was deleted
        if (_selectedCategoryId == category.id) {
          setState(() {
            _selectedCategoryId = null;
          });
        }
        
        // Refresh categories list
        var categoriesResult = await _categoryProvider.get();
        setState(() {
          _categories = categoriesResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: 'Kategorija uspješno obrisana',
        );
      } catch (e) {
        // Extract just the error message without the "Exception: " prefix
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }
        
        NotificationUtility.showError(
          context,
          message: errorMessage,
        );
      }
    }
  }

  Future<void> _showAddSizeDialog({Size? size}) async {
    final isEdit = size != null;
    
    final result = await SizeDialog.show(
      context,
      name: size?.name,
      isEdit: isEdit,
    );
    
    if (result != null) {
      try {
        final sizeData = {'name': result};
        
        if (isEdit && size.id != null) {
          await _sizeProvider.update(size.id!, sizeData);
        } else {
          await _sizeProvider.insert(sizeData);
        }
        
        // Refresh sizes list
        var sizesResult = await _sizeProvider.get();
        setState(() {
          _sizes = sizesResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: isEdit 
            ? 'Veličina uspješno izmijenjena' 
            : 'Veličina uspješno dodana',
        );
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: isEdit
            ? 'Greška u izmjeni veličine: ${e.toString()}'
            : 'Greška u dodavanju veličine: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteSize(Size size) async {
    final confirm = await DialogUtility.showDeleteConfirmation(
      context,
      title: 'Potvrdi brisanje',
      message: 'Da li ste sigurni da želite obrisati veličinu "${size.name ?? ''}"?',
    );
    
    if (confirm) {
      try {
        await _sizeProvider.delete(size.id!);
        
        // Update product sizes if any use this size
        setState(() {
          _productSizes.removeWhere((ps) => ps.size?.id == size.id);
        });
        
        // Refresh sizes list
        var sizesResult = await _sizeProvider.get();
        setState(() {
          _sizes = sizesResult.data;
        });
        
        NotificationUtility.showSuccess(
          context,
          message: 'Veličina uspješno obrisana',
        );
      } catch (e) {
        // Extract just the error message without the "Exception: " prefix
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }
        
        NotificationUtility.showError(
          context,
          message: errorMessage,
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate product sizes
    if (_productSizes.isEmpty) {
      NotificationUtility.showError(
        context,
        message: 'Morate dodati barem jednu veličinu s količinom',
      );
      return;
    }

    for (var size in _productSizes) {
      if (size.size?.id == null ||
          size.quantity == null ||
          size.quantity! <= 0) {
        NotificationUtility.showError(
          context,
          message: 'Sve veličine moraju imati važeću veličinu i količinu',
        );
        return;
      }
    }

    // Prepare product data
    final product = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'barCode': _barcodeController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'colorId': _selectedColorId,
      'categoryId': _selectedCategoryId,
      'isActive': _isActive,
    };

    try {
      if (_selectedProduct == null) {
        // Check if images are available for new product
        if (_selectedImagesBytes.isEmpty || _selectedImageNames.isEmpty) {
          NotificationUtility.showError(
            context,
            message: 'Slike su obavezne za nove proizvode',
          );
          return;
        }

        // Show confirmation dialog before adding new product
        final confirmed = await DialogUtility.showConfirmation(
          context,
          title: 'Potvrdi Dodavanje',
          message: 'Da li ste sigurni da želite dodati ovaj novi proizvod?',
          confirmLabel: 'Potvrdi',
          cancelLabel: 'Otkaži',
        );

        if (!confirmed) {
          return;
        }

        setState(() {
          _isLoading = true;
        });

        // Create new product
        await _productProvider.insertWithImage(
          product,
          _selectedImagesBytes,
          _selectedImageNames,
          _productSizes,
        );

        await _loadData();
        _clearForm();

        NotificationUtility.showSuccess(
          context,
          message: 'Proizvod uspješno kreiran',
        );
      } else {
        // Show confirmation dialog before updating
        final confirmed = await DialogUtility.showConfirmation(
          context,
          title: 'Potvrdi Izmjene',
          message: 'Da li ste sigurni da želite izmijeniti ovaj proizvod?',
          confirmLabel: 'Potvrdi',
          cancelLabel: 'Otkaži',
        );

        if (!confirmed) {
          return;
        }

        setState(() {
          _isLoading = true;
        });

        // Update existing product
        await _productProvider.updateWithImage(
          _selectedProduct!.id!,
          product,
          _selectedImagesBytes.isEmpty ? null : _selectedImagesBytes,
          _selectedImageNames.isEmpty ? null : _selectedImageNames,
          _imagesToKeep.isEmpty ? null : _imagesToKeep,
          _productSizes,
        );

        await _loadData();
        _clearForm();

        NotificationUtility.showSuccess(
          context,
          message: 'Proizvod uspješno izmijenjen',
        );
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Greška u spremanju proizvoda: ${e.toString()}',
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
                    'Shop',
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
                            hintText: 'Pretraži proizvode...',
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
                  // Products list in grid view
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _result == null || _result!.data.isEmpty
                        ? const Center(child: Text('Nema pronađenih proizvoda'))
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _calculateCrossAxisCount(
                                    _searchObject.pageSize ?? 10,
                                  ),
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: _result!.data.length,
                            itemBuilder: (context, index) {
                              final product = _result!.data[index];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: _selectedProduct?.id == product.id
                                        ? Colors.blue.shade700
                                        : Colors.blue.shade300,
                                    width: _selectedProduct?.id == product.id
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _selectProduct(product),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Product image
                                      Expanded(
                                        flex: 4,
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(10),
                                              ),
                                          child: Container(
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child:
                                                product.primaryImageUrl != null
                                                ? Image.network(
                                                    product
                                                            .primaryImageUrl
                                                            ?.imageUrl ??
                                                        '',
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Center(
                                                          child: Icon(
                                                            Icons.image,
                                                            size: 50,
                                                          ),
                                                        ),
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 50,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      // Product name
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          product.name ?? 'Nepoznato ime',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Price
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Action buttons
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.blue,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                color: Colors.blue,
                                                tooltip: 'Izmijeni proizvod',
                                                onPressed: () =>
                                                    _selectProduct(product),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.red,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                ),
                                                color: Colors.red,
                                                tooltip: 'Izbriši proizvod',
                                                onPressed: () =>
                                                    _confirmDeleteProduct(
                                                      product,
                                                    ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
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
                            items: [5, 10, 20, 50]
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
                          child: const Text('Prethodni'),
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
                          child: const Text('Sljedeći'),
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
                        _selectedProduct == null
                            ? 'Dodaj novi proizvod'
                            : 'Izmijeni proizvod',
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
                                'Slike proizvoda',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Image container with validation
                          FormField<bool>(
                            validator: (value) {
                              if (_selectedImagesBytes.isEmpty &&
                                  _selectedProduct == null) {
                                return 'Molimo odaberite barem jednu sliku za proizvod';
                              }
                              return null;
                            },
                            builder: (formFieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Selected images preview
                                  if (_selectedImagesBytes.isNotEmpty)
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _selectedImagesBytes.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: 100,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Image.memory(
                                                    Uint8List.fromList(
                                                      _selectedImagesBytes[index],
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                    ),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.black54,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                    ),
                                                    onPressed: () =>
                                                        _removeImage(index),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else if (_selectedProduct?.primaryImageUrl !=
                                      null)
                                    // Show existing product image
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: formFieldState.hasError
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Image.network(
                                        _selectedProduct!
                                                .primaryImageUrl
                                                ?.imageUrl ??
                                            '',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  else
                                    // Empty image container
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: formFieldState.hasError
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                            Text(
                                              'Nema odabranih slika',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // Upload button
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Učitaj slike'),
                                    onPressed: _pickImages,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),

                                  // Error message below the image container
                                  if (formFieldState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        formFieldState.errorText!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
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
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Product information
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Naziv proizvoda',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Molimo unesite naziv proizvoda';
                          }
                          if (value.length > 100) {
                            return 'Naziv ne može biti duži od 100 znakova';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Opis',
                          border: OutlineInputBorder(),
                          hintText: 'Unesite opis proizvoda',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Molimo unesite opis proizvoda';
                          }
                          if (value.length > 500) {
                            return 'Opis ne može biti duži od 500 znakova';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barkod',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 50) {
                            return 'Barkod ne može biti duži od 50 znakova';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Cijena',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Molimo unesite cijenu proizvoda';
                          }
                          final price = double.tryParse(value);
                          if (price == null) {
                            return 'Molimo unesite važeću cijenu';
                          }
                          if (price <= 0 || price >= 10000) {
                            return 'Cijena mora biti između 0.01 i 10,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Color and Category dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: FormField<int>(
                              initialValue: _selectedColorId,
                              validator: (value) {
                                if (value == null) {
                                  return 'Molimo odaberite boju';
                                }
                                return null;
                              },
                              builder: (FormFieldState<int> state) {
                                return InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Boja',
                                    errorText: state.hasError
                                        ? state.errorText
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                  isEmpty: _selectedColorId == null,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<dynamic>(
                                      value: _selectedColorId,
                                      isDense: true,
                                      isExpanded: true,
                                      // Custom selected item builder to show just the name without buttons
                                      selectedItemBuilder: (BuildContext context) {
                                        return _colors.map<Widget>((model.Color color) {
                                          return Container(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    color: _parseHexColor(color.hexCode ?? '#CCCCCC'),
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                Text(color.name ?? '', overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          );
                                        }).toList()..add(
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Dodaj novu boju', style: TextStyle(color: Colors.blue)),
                                          ),
                                        );
                                      },
                                      onChanged: (dynamic value) {
                                        if (value is String) {
                                          // Handle special actions
                                          if (value == 'add_new') {
                                            _showAddColorDialog();
                                          }
                                        } else {
                                          // Normal selection
                                          setState(() {
                                            _selectedColorId = value;
                                            state.didChange(value);
                                          });
                                        }
                                      },
                                      items: [
                                        // Regular color items
                                        ..._colors.map((model.Color color) {
                                          return DropdownMenuItem<int>(
                                            value: color.id,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      margin: const EdgeInsets.only(right: 8),
                                                      decoration: BoxDecoration(
                                                        color: _parseHexColor(color.hexCode ?? '#CCCCCC'),
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    Text(color.name ?? ''),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, size: 16),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        // Close dropdown and show dialog
                                                        Navigator.pop(context);
                                                        _showAddColorDialog(color: color);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        // Close dropdown and show confirmation
                                                        Navigator.pop(context);
                                                        _deleteColor(color);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        // Add divider if we have colors
                                        if (_colors.isNotEmpty)
                                          const DropdownMenuItem<String>(
                                            value: 'divider',
                                            enabled: false,
                                            child: Divider(),
                                          ),
                                        // Add "Add new" option
                                        const DropdownMenuItem<String>(
                                          value: 'add_new',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_circle, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Dodaj novu boju', style: TextStyle(color: Colors.blue)),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormField<int>(
                              initialValue: _selectedCategoryId,
                              validator: (value) {
                                if (value == null) {
                                  return 'Molimo odaberite kategoriju';
                                }
                                return null;
                              },
                              builder: (FormFieldState<int> state) {
                                return InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Kategorija',
                                    errorText: state.hasError
                                        ? state.errorText
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                  isEmpty: _selectedCategoryId == null,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<dynamic>(
                                      value: _selectedCategoryId,
                                      isDense: true,
                                      isExpanded: true,
                                      // Custom selected item builder to show just the name without buttons
                                      selectedItemBuilder: (BuildContext context) {
                                        return _categories.map<Widget>((Category category) {
                                          return Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(category.name ?? '', overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList()..add(
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Dodaj novu kategoriju', style: TextStyle(color: Colors.blue)),
                                          ),
                                        );
                                      },
                                      onChanged: (dynamic value) {
                                        if (value is String) {
                                          // Handle special actions
                                          if (value == 'add_new') {
                                            _showAddCategoryDialog();
                                          }
                                        } else {
                                          // Normal selection
                                          setState(() {
                                            _selectedCategoryId = value;
                                            state.didChange(value);
                                          });
                                        }
                                      },
                                      items: [
                                        // Regular category items
                                        ..._categories.map((Category category) {
                                          return DropdownMenuItem<int>(
                                            value: category.id,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(category.name ?? ''),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, size: 16),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        // Close dropdown and show dialog
                                                        Navigator.pop(context);
                                                        _showAddCategoryDialog(category: category);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        // Close dropdown and show confirmation
                                                        Navigator.pop(context);
                                                        _deleteCategory(category);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        // Add divider if we have categories
                                        if (_categories.isNotEmpty)
                                          const DropdownMenuItem<String>(
                                            value: 'divider',
                                            enabled: false,
                                            child: Divider(),
                                          ),
                                        // Add "Add new" option
                                        const DropdownMenuItem<String>(
                                          value: 'add_new',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_circle, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Dodaj novu kategoriju', style: TextStyle(color: Colors.blue)),
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Active status
                      CheckboxListTile(
                        title: const Text('Aktiviraj proizvod'),
                        value: _isActive,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? value) {
                          setState(() {
                            _isActive = value ?? true;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Product sizes section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Veličine proizvoda',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Dodaj veličinu'),
                                onPressed: _addProductSize,
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
                          if (_productSizes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Veličine nisu dodane. Kliknite "Dodaj veličinu" za dodavanje veličina proizvoda.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _productSizes.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Size dropdown
                                        Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: DropdownButtonFormField<dynamic>(
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Veličina',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 0,
                                                            ),
                                                      ),
                                                  value: _productSizes[index]
                                                      .size
                                                      ?.id,
                                                  // Custom selected item builder to show just the name without buttons
                                                  selectedItemBuilder: (BuildContext context) {
                                                    return _sizes.map<Widget>((Size size) {
                                                      return Container(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(size.name ?? '', overflow: TextOverflow.ellipsis),
                                                      );
                                                    }).toList()..add(
                                                      Container(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text('Dodaj novu veličinu', style: TextStyle(color: Colors.blue)),
                                                      ),
                                                    );
                                                  },
                                                  items: [
                                                    // Regular size items
                                                    ..._sizes.map((Size size) {
                                                      return DropdownMenuItem<int>(
                                                        value: size.id,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(size.name ?? ''),
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, size: 16),
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              onPressed: () {
                                                                // Close dropdown and show dialog
                                                                Navigator.pop(context);
                                                                _showAddSizeDialog(size: size);
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              onPressed: () {
                                                                // Close dropdown and show confirmation
                                                                Navigator.pop(context);
                                                                _deleteSize(size);
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                    // Add divider if we have sizes
                                                    if (_sizes.isNotEmpty)
                                                      const DropdownMenuItem<String>(
                                                        value: 'divider',
                                                        enabled: false,
                                                        child: Divider(),
                                                      ),
                                                    // Add "Add new" option
                                                    DropdownMenuItem<String>(
                                                      value: 'add_new',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.add_circle, color: Colors.blue, size: 16),
                                                          SizedBox(width: 8),
                                                          Text('Dodaj novu veličinu', 
                                                            style: TextStyle(color: Colors.blue, fontSize: 13),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onChanged: (dynamic value) {
                                                    if (value is String) {
                                                      // Handle special actions
                                                      if (value == 'add_new') {
                                                        _showAddSizeDialog();
                                                      }
                                                    } else {
                                                      // Normal selection
                                                      _updateProductSize(
                                                        index,
                                                        value,
                                                        _productSizes[index].quantity,
                                                      );
                                                    }
                                                  },
                                                  validator: (value) {
                                                    if (value == null || value is String) {
                                                      return 'Obavezno';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Quantity field
                                        Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'Količina',
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 0,
                                                  ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            initialValue:
                                                _productSizes[index].quantity
                                                    ?.toString() ??
                                                '0',
                                            onChanged: (value) =>
                                                _updateProductSize(
                                                  index,
                                                  _productSizes[index]
                                                          .size
                                                          ?.id ??
                                                      null,
                                                  int.tryParse(value) ?? 0,
                                                ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Obavezno';
                                              }
                                              final quantity = int.tryParse(
                                                value,
                                              );
                                              if (quantity == null) {
                                                return 'Nevažeće';
                                              }
                                              if (quantity < 0 ||
                                                  quantity > 10000) {
                                                return '0-10000';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        // Remove button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          onPressed: () =>
                                              _removeProductSize(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
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
                            onPressed: _isLoading ? null : _saveProduct,
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
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _selectedProduct == null
                                        ? 'Dodaj proizvod'
                                        : 'Sačuvaj izmene',
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
