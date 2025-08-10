import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';

/// Shop screen with product categories and items
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Sve';
  final List<String> _categories = ['Sve', 'Dresovi', 'Oprema', 'Suveniri', 'Dodaci'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Categories horizontal list
        _buildCategoriesSection(),
        
        // Add product button
        _buildAddProductButton(),
        
        // Products grid
        Expanded(
          child: _buildProductsGrid(),
        ),
      ],
    );
  }

  /// Build categories section
  Widget _buildCategoriesSection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: ResponsiveHelper.font(context, base: 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build add product button
  Widget _buildAddProductButton() {
    return Container(
      margin: ResponsiveHelper.pagePadding(context).copyWith(top: 0, bottom: 8),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: InkWell(
          onTap: () {
            NotificationHelper.showInfo(context, 'Dodavanje novog proizvoda...');
            // TODO: Navigate to add product screen
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dodaj novi proizvod',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 16),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build products grid
  Widget _buildProductsGrid() {
    final products = _getFilteredProducts();
    
    return GridView.builder(
      padding: ResponsiveHelper.pagePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 2 : 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: InkWell(
        onTap: () {
          NotificationHelper.showInfo(context, 'Otvaranje detalja proizvoda...');
          // TODO: Navigate to product details
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Icon(
                  _getProductIcon(product['category']),
                  size: ResponsiveHelper.iconSize(context) + 16,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                ),
              ),
            ),
            
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product['name'],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Category
                    Text(
                      product['category'],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price and stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product['price']} KM',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 16),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product['stock'] > 0 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product['stock']}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 10),
                              color: product['stock'] > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
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

  /// Get icon for product category
  IconData _getProductIcon(String category) {
    switch (category) {
      case 'Dresovi':
        return Icons.sports_soccer;
      case 'Oprema':
        return Icons.sports;
      case 'Suveniri':
        return Icons.card_giftcard;
      case 'Dodaci':
        return Icons.shopping_bag;
      default:
        return Icons.inventory;
    }
  }

  /// Get filtered products based on selected category
  List<Map<String, dynamic>> _getFilteredProducts() {
    final allProducts = _getMockProducts();
    
    if (_selectedCategory == 'Sve') {
      return allProducts;
    }
    
    return allProducts.where((product) => product['category'] == _selectedCategory).toList();
  }

  /// Get mock products data
  List<Map<String, dynamic>> _getMockProducts() {
    return [
      {
        'name': 'Dres MyClub 2024/25',
        'category': 'Dresovi',
        'price': 89,
        'stock': 15,
      },
      {
        'name': 'Fudbalska lopta Nike',
        'category': 'Oprema',
        'price': 45,
        'stock': 8,
      },
      {
        'name': 'Šolja sa logom',
        'category': 'Suveniri',
        'price': 12,
        'stock': 25,
      },
      {
        'name': 'Sportska torba',
        'category': 'Dodaci',
        'price': 35,
        'stock': 5,
      },
      {
        'name': 'Gostujući dres',
        'category': 'Dresovi',
        'price': 79,
        'stock': 12,
      },
      {
        'name': 'Kopačke Adidas',
        'category': 'Oprema',
        'price': 150,
        'stock': 3,
      },
      {
        'name': 'Šal navijača',
        'category': 'Suveniri',
        'price': 20,
        'stock': 18,
      },
      {
        'name': 'Kačket MyClub',
        'category': 'Dodaci',
        'price': 25,
        'stock': 0,
      },
      {
        'name': 'Treći dres',
        'category': 'Dresovi',
        'price': 85,
        'stock': 7,
      },
    ];
  }
}
