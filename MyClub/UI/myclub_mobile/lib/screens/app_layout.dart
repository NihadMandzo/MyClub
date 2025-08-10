import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import 'home_screen.dart';
import 'match_screen.dart';
import 'shop_screen.dart';
import 'info_screen.dart';

/// Main application layout with top navbar, bottom navbar, and screen content
/// Rebuilds screens on tab change instead of preserving state
class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0;

  /// List of screen builders - each call creates a new instance
  /// This ensures no state preservation between tab switches
  List<Widget Function()> get _screenBuilders => [
    () => const HomeScreen(),
    () => const MatchScreen(),
    () => const ShopScreen(),
    () => const InfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top navigation bar
      appBar: TopNavBar(
        showCart: _currentIndex == 2, // Show cart only on Shop tab (index 2)
        cartItemsCount: 0, // TODO: Connect to cart provider
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
  }
}
