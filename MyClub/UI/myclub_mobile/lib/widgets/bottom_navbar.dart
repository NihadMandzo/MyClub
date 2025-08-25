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
      backgroundColor: Theme.of(context).colorScheme.primary,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelTextStyle: WidgetStateProperty.all(TextStyle(color: Color(0xFFFFFFFF))),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined, color: Color(0xFFFFFFFF)), label: 'Početna'),
        NavigationDestination(icon: Icon(Icons.sports_soccer_outlined, color: Color(0xFFFFFFFF)), label: 'Utakmice'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined, color: Color(0xFFFFFFFF)), label: 'Fan shop'),
        NavigationDestination(icon: Icon(Icons.menu, color: Color(0xFFFFFFFF)), label: 'Info'),
      ],
    );
  }
}
