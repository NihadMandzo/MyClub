import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../utility/auth_helper.dart';
import '../screens/profile_screen.dart';

/// Top navigation bar widget with club logo, cart icon (conditional), and profile icon
class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  /// Whether to show the cart icon (only shown on Shop screen)
  final bool showCart;
  
  /// Optional cart items count for badge
  final int cartItemsCount;

  /// Callback for cart icon press
  final VoidCallback? onCartTap;

  /// Callback for profile icon press
  final VoidCallback? onProfileTap;

  const TopNavBar({
    super.key,
    this.showCart = false,
    this.cartItemsCount = 0,
    this.onCartTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: ResponsiveHelper.cardElevation(context),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Club Logo
          _buildClubLogo(context),
          
          const Spacer(),
          
          // Cart Icon (conditional)
          if (showCart) _buildCartIcon(context),
          
          // Profile Icon
          _buildProfileIcon(context),
        ],
      ),
    );
  }

  /// Build the club logo widget
  Widget _buildClubLogo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.sports_soccer,
          size: ResponsiveHelper.iconSize(context),
          color: Colors.white,
        ),
        SizedBox(width: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 4 : 8),
        Text(
          'MyClub',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Build the cart icon with badge
  Widget _buildCartIcon(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 8 : 12,
      ),
      child: Stack(
        children: [
          IconButton(
            onPressed: onCartTap ?? () => _onCartPressed(context),
            icon: Icon(
              Icons.shopping_cart,
              size: ResponsiveHelper.iconSize(context),
              color: Colors.white,
            ),
          ),
          if (cartItemsCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$cartItemsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the profile icon
  Widget _buildProfileIcon(BuildContext context) {
    return IconButton(
      onPressed: onProfileTap ?? () => showProfileOptions(context),
      icon: Icon(
        Icons.account_circle,
        size: ResponsiveHelper.iconSize(context),
        color: Colors.white,
      ),
    );
  }

  /// Handle cart icon press
  void _onCartPressed(BuildContext context) {
    NotificationHelper.showInfo(context, 'Otvaranje korpe...');
    // TODO: Navigate to cart screen or show cart bottom sheet
  }

  /// Alternative method to show profile bottom sheet (if needed)
  void showProfileOptions(BuildContext context) {
    _showProfileBottomSheet(context);
  }

  /// Show profile options bottom sheet
  void _showProfileBottomSheet(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    NotificationHelper.showCustomBottomSheet(
      context: context,
      child: Container(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Profile info
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              subtitle: Text(authProvider.username ?? 'Nepoznato'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            
            const Divider(),
            
            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Odjavi se', style: TextStyle(color: Colors.red)),
              onTap: () => _handleLogout(context),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Handle logout with confirmation
  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet
    
    final confirmed = await NotificationHelper.showConfirmDialog(
      context: context,
      title: 'Odjava',
      message: 'Jeste li sigurni da se želite odjaviti?',
      confirmText: 'Odjavi se',
      cancelText: 'Otkaži',
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      await AuthHelper.clearAuthData();
      NotificationHelper.showSuccess(context, 'Uspješno ste se odjavili.');
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
