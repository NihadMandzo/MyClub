import 'package:flutter/material.dart';

/// Bottom navigation with 4 tabs. No state preservation is enforced by the parent
/// by rebuilding screens rather than using an IndexedStack.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), label: 'Match'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.menu), label: 'Info'),
      ],
    );
  }
}
