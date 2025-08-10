import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';

/// Home screen with responsive layout and example content
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 20),
          _buildStatsSection(context),
          const SizedBox(height: 20),
          _buildRecentActivities(context),
          const SizedBox(height: 20),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  /// Build welcome card with user info
  Widget _buildWelcomeCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          elevation: ResponsiveHelper.cardElevation(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dobrodošli,',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 16),
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.username ?? 'Korisnik',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vaša uloga: ${authProvider.roleName ?? 'Administrator'}',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 14),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build statistics section
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistike',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Članovi', '127', Icons.people)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Utakmice', '8', Icons.sports_soccer)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Prodavnica', '24', Icons.storefront)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Aktivni', '89', Icons.trending_up)),
          ],
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.iconSize(context),
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 24),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 12),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build recent activities section
  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Najnovije aktivnosti',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: ResponsiveHelper.cardElevation(context),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'Nova utakmica zakazana',
                'Sutra u 18:00',
                Icons.sports_soccer,
                Colors.green,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Novi proizvod u prodavnici',
                'Dres 2024/25',
                Icons.storefront,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Novi član registrovan',
                'Marko Petrović',
                Icons.person_add,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual activity item
  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveHelper.font(context, base: 14),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveHelper.font(context, base: 12),
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: () {
        // TODO: Navigate to detail view
      },
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brze akcije',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(context, 'Dodaj člana', Icons.person_add, Colors.green),
            _buildActionCard(context, 'Nova utakmica', Icons.add_circle, Colors.blue),
            _buildActionCard(context, 'Dodaj proizvod', Icons.add_shopping_cart, Colors.orange),
            _buildActionCard(context, 'Izvještaji', Icons.analytics, Colors.purple),
            _buildActionCard(context, 'Postavke', Icons.settings, Colors.grey),
            _buildActionCard(context, 'Pomoć', Icons.help, Colors.teal),
          ],
        ),
      ],
    );
  }

  /// Build individual action card
  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: InkWell(
        onTap: () {
          // TODO: Handle action
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.iconSize(context) + 4,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
