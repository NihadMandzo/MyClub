import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import 'profile_screen.dart';

/// Info screen with various options and club information
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClubInfoCard(context),
        ],
      ),
    );
  }

  /// Build club information card
  Widget _buildClubInfoCard(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sports_soccer,
              size: ResponsiveHelper.iconSize(context) + 20,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'MyClub',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 28),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Osnovan 1945.',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, '80', 'Godine'),
                _buildStatItem(context, '127', 'Članovi'),
                _buildStatItem(context, '15', 'Trofеji'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 12),
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Build menu section
  Widget _buildMenuSection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: ResponsiveHelper.cardElevation(context),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildMenuItem(context, item),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Build individual menu item
  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    return ListTile(
      leading: Icon(
        item['icon'],
        color: item['color'] ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        item['title'],
        style: TextStyle(
          fontSize: ResponsiveHelper.font(context, base: 16),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: item['subtitle'] != null
          ? Text(
              item['subtitle'],
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _handleMenuItemTap(context, item),
    );
  }

  /// Handle menu item tap
  void _handleMenuItemTap(BuildContext context, Map<String, dynamic> item) {
    NotificationHelper.showInfo(context, 'Otvaranje: ${item['title']}');
  }

}
