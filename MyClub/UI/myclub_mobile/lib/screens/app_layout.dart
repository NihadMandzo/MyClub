import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';
import 'match_screen.dart';
import 'shop_screen.dart';
import 'info_screen.dart';
import 'cart_screen.dart';

/// Main application layout with top navbar, bottom navbar, and screen content
/// Rebuilds screens on tab change instead of preserving state
class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0;
  int _cartItemsCount = 0;
  late CartProvider _cartProvider;

  @override
  void initState() {
    super.initState();
    _cartProvider = context.read<CartProvider>();
    _cartProvider.setContext(context);
    _loadCartItemsCount();
  }

  /// Load cart items count
  Future<void> _loadCartItemsCount() async {
    try {
      final cart = await _cartProvider.getCurrentUserCart();
      setState(() {
        _cartItemsCount = cart?.totalItemsCount ?? 0;
      });
    } catch (e) {
      // Silently handle error - cart count will remain 0
      setState(() {
        _cartItemsCount = 0;
      });
    }
  }

  /// List of screen builders - each call creates a new instance
  /// This ensures no state preservation between tab switches
  List<Widget Function()> get _screenBuilders => [
    () => const HomeScreen(),
    () => const MatchScreen(),
    () => ShopScreen(onCartUpdated: _loadCartItemsCount),
    () => const InfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top navigation bar
      appBar: TopNavBar(
        showCart: _currentIndex == 2, // Show cart only on Shop tab (index 2)
        cartItemsCount: _cartItemsCount,
        onCartTap: () async {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CartScreen()),
          ).then((_) {
            // Reload cart count when returning from cart screen
            _loadCartItemsCount();
          });
        },
        onRefreshCart: _loadCartItemsCount,
      ),
      
      // Current screen content - rebuilt on every tab change
      body: _screenBuilders[_currentIndex](),
      
      // Bottom navigation bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  /// Handle tab selection - rebuild screen instead of preserving state
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Reload cart count when switching to shop tab
    if (index == 2) {
      _loadCartItemsCount();
    }
  }
}
