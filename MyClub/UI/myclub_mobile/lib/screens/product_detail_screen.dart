import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/responses/product_response.dart';
import '../providers/product_provider.dart';
import '../widgets/image_gallery_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductProvider _productProvider;
  ProductResponse? _product;
  bool _isLoading = false;
  int _selectedImageIndex = 0;
  String? _selectedSize;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

    Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _addToCart() {
    if (_selectedSize == null && _product!.sizes.isNotEmpty) {
      _showErrorSnackBar('Molimo odaberite veličinu');
      return;
    }

    // TODO: Implement add to cart functionality
    _showSuccessSnackBar('$_selectedQuantity proizvod(a) je dodato u korpu!');
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
      appBar: AppBar(
        title: Text(_product?.name ?? 'Detalji proizvoda'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(
                  child: Text(
                    'Proizvod nije pronađen',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                        padding: const EdgeInsets.all(16),
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
                            
                            const SizedBox(height: 24),
                            
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
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
        ),
        
        // Image thumbnails
        if (images.length > 1)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  onLongPress: () => _openImageGallery(index),
                  child: Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(right: 8),
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
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.image,
                                  size: 32,
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
        
        // Tap instruction text
        if (images.isNotEmpty && images[_selectedImageIndex].imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ],
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _product!.category.name,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Šifra: ${_product!.barCode}',
          style: TextStyle(
            fontSize: 14,
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        if (_product!.rating != null)
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                _product!.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
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
        const Text(
          'Boja',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
                      width: 16,
                      height: 16,
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
                    style: const TextStyle(
                      fontSize: 16,
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
        const Text(
          'Veličina',
          style: TextStyle(
            fontSize: 18,
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
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      '(${productSize.quantity})',
                      style: TextStyle(
                        fontSize: 12,
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
        const Text(
          'Količina',
          style: TextStyle(
            fontSize: 18,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: BorderRadius.circular(8),
                  items: List.generate(10, (index) => index + 1)
                      .map((quantity) => DropdownMenuItem<int>(
                            value: quantity,
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(fontSize: 16),
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
                fontSize: 16,
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
        const Text(
          'Opis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _product!.description,
          style: const TextStyle(
            fontSize: 16,
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
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
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
