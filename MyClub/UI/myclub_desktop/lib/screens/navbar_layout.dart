import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

typedef NavSelectedCallback = void Function(int index);

class NavbarLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final NavSelectedCallback? onNavSelected;

  const NavbarLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.currentIndex,
    this.onNavSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Slightly taller app bar
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 19, 26, 158),
          foregroundColor: Colors.white,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_soccer,
                  color: Color.fromARGB(255, 19, 26, 158),
                  size: 24,
                ),
              ),
            ),
          ),
          title: Container(
            width: double.infinity,
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildNavButton(context, 'Dashboard', 0),
                  buildNavButton(context, 'Orders', 1),
                  buildNavButton(context, 'Shop', 2),
                  buildNavButton(context, 'News', 3),
                  buildNavButton(context, 'Tickets', 4),
                  buildNavButton(context, 'Membership', 5),
                  buildNavButton(context, 'Players', 6),
                  buildNavButton(context, 'Matches', 7),
                ],
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, size: 28),
              tooltip: 'Profile',
              onSelected: (value) {
                if (value == 'logout') {
                  authProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } else if (value == 'settings') {
                  if (onNavSelected != null) {
                    onNavSelected!(8); // 8 is the index for Settings in the screens list
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "User: ${authProvider.user?.username ?? "Guest"}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Color.fromARGB(255, 19, 26, 158)),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
  
  Widget buildNavButton(BuildContext context, String label, int index) {
    bool isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: isSelected
            ? null
            : () {
                if (onNavSelected != null) {
                  onNavSelected!(index);
                }
              },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
