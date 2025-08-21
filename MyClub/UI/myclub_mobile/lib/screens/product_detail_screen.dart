import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/responses/product_response.dart';
import '../models/requests/cart_item_upsert_request.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/image_gallery_viewer.dart';
import '../widgets/top_navbar.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final VoidCallback? onCartUpdated;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    this.onCartUpdated,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductProvider _productProvider;
  late CartProvider _cartProvider;
  ProductResponse? _product;
  bool _isLoading = false;
  bool _isAddingToCart = false;
  int _selectedImageIndex = 0;
  String? _selectedSize;
  int _selectedProductSizeId = 0;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();
    _cartProvider = context.read<CartProvider>();
    _cartProvider.setContext(context);
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _productProvider.getById(widget.productId);
      setState(() {
        _product = product;
      });
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju proizvoda: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _addToCart() async {
    if (_selectedSize == null && _product!.sizes.isNotEmpty) {
      NotificationHelper.showError(context, 'Molimo odaberite veličinu');
      return;
    }

    // Use the tracked product size ID
    int productSizeId = _selectedProductSizeId;
    if (productSizeId == 0 && _product!.sizes.isNotEmpty) {
      NotificationHelper.showError(context, 'Greška pri određivanju veličine proizvoda');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final request = CartItemUpsertRequest(
        productSizeId: productSizeId,
        quantity: _selectedQuantity,
      );

      await _cartProvider.addToCart(request);
      
      // Call the callback to refresh cart count in parent
      if (widget.onCartUpdated != null) {
        widget.onCartUpdated!();
      }
      
      if (mounted) {
        NotificationHelper.showSuccess(
          context, 
          '$_selectedQuantity ${_selectedQuantity == 1 ? 'proizvod je dodat' : 'proizvoda je dodato'} u korpu!'
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri dodavanju u korpu: $e');
      }
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  void _openImageGallery(int initialIndex) {
    if (_product == null || _product!.imageUrls.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          images: _product!.imageUrls,
          initialIndex: _selectedImageIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        showBackButton: true,
        showCart: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? Center(
                  child: Text(
                    'Proizvod nije pronađen',
                    style: TextStyle(fontSize: ResponsiveHelper.font(context, base: 16), color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product images
                      _buildImageGallery(),
                      
                      // Product details
                      Padding(
                        padding: ResponsiveHelper.pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name and category
                            _buildProductHeader(),
                            
                            const SizedBox(height: 16),
                            
                            // Price and rating
                            _buildPriceAndRating(),
                            
                            const SizedBox(height: 16),
                            
                            // Color
                            _buildColorSection(),
                            
                            const SizedBox(height: 16),
                            
                            // Sizes
                            if (_product!.sizes.isNotEmpty) _buildSizeSection(),
                            
                            const SizedBox(height: 16),
                            
                            // Quantity
                            _buildQuantitySection(),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            _buildDescriptionSection(),
                            
                            const SizedBox(height: 20),
                            
                            // Add to cart button
                            _buildAddToCartButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildImageGallery() {
    final images = _product!.imageUrls;

    return Column(
      children: [
        // Main image
        GestureDetector(
          onTap: () => _openImageGallery(0),
          child: Hero(
            tag: 'product_image_${_selectedImageIndex}',
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: images[_selectedImageIndex].imageUrl.isNotEmpty
                  ? Container(
                      color: Colors.white,
                      child: Image.network(
                        images[_selectedImageIndex].imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.image_not_supported,
                              size: ResponsiveHelper.iconSize(context) * 3,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.image,
                        size: ResponsiveHelper.iconSize(context) * 3,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
        ),
        
        // Image thumbnails
        if (images.length > 1)
          Container(
            height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 70 : 80,
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: ResponsiveHelper.pagePadding(context),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                final thumbSize = ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 54.0 : 64.0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  onLongPress: () => _openImageGallery(index),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    margin: EdgeInsets.only(
                      right: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        color: Colors.white,
                        child: images[index].imageUrl.isNotEmpty
                            ? Image.network(
                                images[index].imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: ResponsiveHelper.iconSize(context),
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.image,
                                  size: ResponsiveHelper.iconSize(context),
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!.name,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 24),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _product!.category.name,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Šifra: ${_product!.barCode}',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 14),
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_product!.price.toStringAsFixed(2)} KM',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 28),
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        if (_product!.rating != null)
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: ResponsiveHelper.iconSize(context) * 0.8,
              ),
              const SizedBox(width: 4),
              Text(
                _product!.rating!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boja',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
                      width: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 14 : 16,
                      height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 14 : 16,
                      decoration: BoxDecoration(
                        color: _parseColor(_product!.color.hexCode),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                        ),
                      ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product!.color.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Veličina',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _product!.sizes.map((productSize) {
            final isSelected = _selectedSize == productSize.size.name;
            final isAvailable = productSize.quantity > 0;
            
            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedSize = productSize.size.name;
                        _selectedProductSizeId = productSize.productSizeId;
                      });
                    }
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 12 : 16,
                  vertical: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue
                        : isAvailable
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? Colors.blue.shade50
                      : isAvailable
                          ? Colors.white
                          : Colors.grey.shade100,
                ),
                child: Column(
                  children: [
                    Text(
                      productSize.size.name,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 16),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      '(${productSize.quantity})',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: isAvailable ? Colors.grey.shade600 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Količina',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedQuantity,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 10 : 12,
                    vertical: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  items: List.generate(10, (index) => index + 1)
                      .map((quantity) => DropdownMenuItem<int>(
                            value: quantity,
                            child: Text(
                              quantity.toString(),
                              style: TextStyle(fontSize: ResponsiveHelper.font(context, base: 16)),
                            ),
                          ))
                      .toList(),
                  onChanged: (int? newQuantity) {
                    if (newQuantity != null) {
                      setState(() {
                        _selectedQuantity = newQuantity;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'komad${_selectedQuantity == 1 ? '' : 'a'}',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opis',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _product!.description,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAddingToCart ? null : _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isAddingToCart
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _selectedQuantity == 1 
                        ? 'Dodaj u korpu' 
                        : 'Dodaj $_selectedQuantity u korpu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
