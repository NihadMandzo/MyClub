import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/responses/cart_response.dart';
import '../models/responses/cart_item_response.dart';
import '../models/requests/cart_item_upsert_request.dart';
import '../providers/cart_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../widgets/top_navbar.dart';

/// Cart screen showing user's cart items and total
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartProvider _cartProvider;
  CartResponse? _cart;
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _cartProvider = context.read<CartProvider>();
    _cartProvider.setContext(context);
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cart = await _cartProvider.getCurrentUserCart();
      setState(() {
        _cart = cart;
      });
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju korpe: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItemResponse item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final request = CartItemUpsertRequest(
        productSizeId: item.productSizeId,
        quantity: newQuantity,
      );

      await _cartProvider.updateCartItem(item.id, request);
      await _loadCart(); // Reload cart to get updated totals
      
      if (mounted) {
        NotificationHelper.showSuccess(context, 'Količina je ažurirana');
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri ažuriranju količine: $e');
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _removeItem(CartItemResponse item) async {
    final confirmed = await NotificationHelper.showConfirmDialog(
      context: context,
      title: 'Ukloni stavku',
      message: 'Jeste li sigurni da želite ukloniti "${item.productName}" iz korpe?',
      confirmText: 'Ukloni',
      cancelText: 'Otkaži',
      confirmButtonColor: Colors.red,
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _cartProvider.removeFromCart(item.id);
      await _loadCart(); // Reload cart
      
      if (mounted) {
        NotificationHelper.showSuccess(context, 'Stavka je uklonjena iz korpe');
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri uklanjanju stavke: $e');
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await NotificationHelper.showConfirmDialog(
      context: context,
      title: 'Obriši korpu',
      message: 'Jeste li sigurni da želite obrisati sve stavke iz korpe?',
      confirmText: 'Obriši',
      cancelText: 'Otkaži',
      confirmButtonColor: Colors.red,
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _cartProvider.clearCart();
      await _loadCart(); // Reload cart
      
      if (mounted) {
        NotificationHelper.showSuccess(context, 'Korpa je obrisana');
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri brisanju korpe: $e');
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _proceedToCheckout() {
    // TODO: Implement checkout functionality
    NotificationHelper.showInfo(context, 'Funkcija checkout-a će biti implementirana...');
  }

  @override
  Widget build(BuildContext context) {
    final cartItemsCount = _cart?.totalItemsCount ?? 0;

    return Scaffold(
      appBar: TopNavBar(
        showCart: false, // Don't show cart icon on cart screen
        showBackButton: true, // Show back button to return to previous screen
        cartItemsCount: cartItemsCount,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Vaša korpa je prazna',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 20),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodajte proizvode u korpu da biste nastavili sa kupovinom',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Nastavi kupovinu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart header
        Container(
          padding: ResponsiveHelper.pagePadding(context),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Korpa (${_cart!.totalItemsCount} stavke)',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_cart!.isNotEmpty)
                    TextButton(
                      onPressed: _isUpdating ? null : _clearCart,
                      child: Text(
                        'Obriši sve',
                        style: TextStyle(
                          color: _isUpdating ? Colors.grey : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Membership status
              if (_cart!.hasActiveMembership == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Aktivno članstvo - 20% popust',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Cart items
        Expanded(
          child: _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: ResponsiveHelper.pagePadding(context),
                  itemCount: _cart!.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = _cart!.items[index];
                    return _buildCartItem(item);
                  },
                ),
        ),

        // Bottom total and checkout
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildCartItem(CartItemResponse item) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Veličina: ${item.sizeName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(2)} KM',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Quantity controls and subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity controls
                      Row(
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onTap: () => _updateQuantity(item, item.quantity - 1),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onTap: () => _updateQuantity(item, item.quantity + 1),
                          ),
                        ],
                      ),
                      
                      // Subtotal
                      Text(
                        '${item.subtotal.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () => _removeItem(item),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Ukloni stavku',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isUpdating ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: _isUpdating ? Colors.grey.shade100 : Colors.white,
        ),
        child: Icon(
          icon,
          size: 18,
          color: _isUpdating ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: ResponsiveHelper.pagePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_cart!.totalAmount.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Membership discount (if applicable)
            if (_cart!.hasActiveMembership == true) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Članovski popust (20%):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${_cart!.membershipDiscount.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ukupno:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_cart!.finalAmount.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Nastavi na plaćanje - ${_cart!.finalAmount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
