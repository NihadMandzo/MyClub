import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';

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
          const SizedBox(height: 20),
          _buildMenuSection(context, 'Upravljanje', _getManagementItems()),
          const SizedBox(height: 20),
          _buildMenuSection(context, 'Izvještaji', _getReportsItems()),
          const SizedBox(height: 20),
          _buildMenuSection(context, 'Općenito', _getGeneralItems()),
          const SizedBox(height: 20),
          _buildMenuSection(context, 'Podrška', _getSupportItems()),
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
    // TODO: Navigate to respective screens
  }

  /// Get management menu items
  List<Map<String, dynamic>> _getManagementItems() {
    return [
      {
        'title': 'Upravljanje članovima',
        'subtitle': 'Dodaj, uredi ili ukloni članove',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Upravljanje utakmicama',
        'subtitle': 'Zakaži ili uredi utakmice',
        'icon': Icons.sports_soccer,
        'color': Colors.green,
      },
      {
        'title': 'Upravljanje prodavnicom',
        'subtitle': 'Dodaj ili uredi proizvode',
        'icon': Icons.storefront,
        'color': Colors.orange,
      },
      {
        'title': 'Korisničke uloge',
        'subtitle': 'Upravljaj dozvolama',
        'icon': Icons.admin_panel_settings,
        'color': Colors.purple,
      },
    ];
  }

  /// Get reports menu items
  List<Map<String, dynamic>> _getReportsItems() {
    return [
      {
        'title': 'Finansijski izvještaji',
        'subtitle': 'Pregled prihoda i rashoda',
        'icon': Icons.analytics,
        'color': Colors.teal,
      },
      {
        'title': 'Izvještaj članstva',
        'subtitle': 'Statistike članova',
        'icon': Icons.assessment,
        'color': Colors.indigo,
      },
      {
        'title': 'Prodajni izvještaji',
        'subtitle': 'Analiza prodaje',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
    ];
  }

  /// Get general menu items
  List<Map<String, dynamic>> _getGeneralItems() {
    return [
      {
        'title': 'Obavještenja',
        'subtitle': 'Postavke obavještenja',
        'icon': Icons.notifications,
        'color': Colors.amber,
      },
      {
        'title': 'Sigurnost',
        'subtitle': 'Lozinka i sigurnost',
        'icon': Icons.security,
        'color': Colors.red,
      },
      {
        'title': 'O aplikaciji',
        'subtitle': 'Verzija 1.0.0',
        'icon': Icons.info,
        'color': Colors.grey,
      },
    ];
  }

  /// Get support menu items
  List<Map<String, dynamic>> _getSupportItems() {
    return [
      {
        'title': 'Pomoć i podrška',
        'subtitle': 'Često postavljena pitanja',
        'icon': Icons.help,
        'color': Colors.cyan,
      },
      {
        'title': 'Kontakt',
        'subtitle': 'Kontaktirajte nas',
        'icon': Icons.contact_support,
        'color': Colors.pink,
      },
      {
        'title': 'Povratne informacije',
        'subtitle': 'Pošaljite nam feedback',
        'icon': Icons.feedback,
        'color': Colors.lime,
      },
    ];
  }
}
