import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../providers/user_provider.dart';
import '../models/responses/user.dart';

/// Profile screen with user information, edit/deactivate buttons, and expandable cards
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isTicketsExpanded = false;
  bool _isOrdersExpanded = false;
  bool _isMembershipExpanded = false;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = await userProvider.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      
      if (user == null && mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju korisničkih podataka');
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju korisničkih podataka');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: ResponsiveHelper.cardElevation(context),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Moj Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _handleEditProfile(context),
            icon: const Icon(Icons.edit),
            tooltip: 'Uredi profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ResponsiveHelper.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 20),
                    _buildActionButtons(context),
                    const SizedBox(height: 30),
                    _buildExpandableCard(
                      context,
                      title: 'Moje ulaznice',
                      icon: Icons.confirmation_number,
                      color: Colors.blue,
                      isExpanded: _isTicketsExpanded,
                      onTap: () => setState(() => _isTicketsExpanded = !_isTicketsExpanded),
                      content: _buildTicketsContent(),
                    ),
                    const SizedBox(height: 16),
                    _buildExpandableCard(
                      context,
                      title: 'Moje narudžbe',
                      icon: Icons.shopping_bag,
                      color: Colors.green,
                      isExpanded: _isOrdersExpanded,
                      onTap: () => setState(() => _isOrdersExpanded = !_isOrdersExpanded),
                      content: _buildOrdersContent(),
                    ),
                    const SizedBox(height: 16),
                    _buildExpandableCard(
                      context,
                      title: 'Moje članstvo',
                      icon: Icons.card_membership,
                      color: Colors.purple,
                      isExpanded: _isMembershipExpanded,
                      onTap: () => setState(() => _isMembershipExpanded = !_isMembershipExpanded),
                      content: _buildMembershipContent(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build profile header with user info
  Widget _buildProfileHeader(BuildContext context) {
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
            CircleAvatar(
              radius: ResponsiveHelper.iconSize(context) + 10,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: ResponsiveHelper.iconSize(context) + 5,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser?.fullName ?? 'Nepoznato ime',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 24),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?.email ?? 'Nepoznat email',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?.createdAt != null 
                  ? 'Član od ${_currentUser!.createdAt.year}.'
                  : 'Član od nepoznato',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat(context, '15', 'Ulaznica'),
                _buildProfileStat(context, '8', 'Narudžbi'),
                _buildProfileStat(
                  context, 
                  _currentUser?.createdAt != null 
                      ? '${DateTime.now().year - _currentUser!.createdAt.year}'
                      : '0',
                  'Godine'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual profile stat item
  Widget _buildProfileStat(BuildContext context, String value, String label) {
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

  /// Build action buttons (Edit Profile and Deactivate)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleEditProfile(context),
            icon: const Icon(Icons.edit),
            label: const Text('Uredi profil'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleDeactivateProfile(context),
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text(
              'Deaktiviraj',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build expandable card
  Widget _buildExpandableCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon, color: color),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.expand_more),
              ),
              onTap: onTap,
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: content,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  /// Build tickets content
  Widget _buildTicketsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nadolazeće utakmice',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildTicketItem(
            context,
            'FC MyClub vs Dinamo',
            '15. Avgust 2025, 20:00',
            'Sektor A, Red 5, Sjedište 12',
            Icons.sports_soccer,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildTicketItem(
            context,
            'FC MyClub vs Sarajevo',
            '22. Avgust 2025, 19:00',
            'Sektor B, Red 3, Sjedište 8',
            Icons.sports_soccer,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Prethodne utakmice',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildTicketItem(
            context,
            'FC MyClub vs Željezničar',
            '1. Avgust 2025, 21:00',
            'Sektor A, Red 2, Sjedište 15',
            Icons.sports_soccer,
            Colors.grey,
            isUsed: true,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => NotificationHelper.showInfo(context, 'Prikazivanje svih ulaznica'),
              child: const Text('Prikaži sve ulaznice'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build orders content
  Widget _buildOrdersContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivne narudžbe',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderItem(
            context,
            'Narudžba #001234',
            '50.00 KM',
            'Dres MyClub 2024/25',
            '5. Avgust 2025',
            Icons.local_shipping,
            Colors.orange,
            'U transportu',
          ),
          const SizedBox(height: 16),
          Text(
            'Prethodne narudžbe',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderItem(
            context,
            'Narudžba #001230',
            '25.00 KM',
            'Šal MyClub',
            '28. Juli 2025',
            Icons.check_circle,
            Colors.green,
            'Dostavljeno',
          ),
          const SizedBox(height: 8),
          _buildOrderItem(
            context,
            'Narudžba #001225',
            '75.00 KM',
            'Dres + Šorts',
            '15. Juli 2025',
            Icons.check_circle,
            Colors.green,
            'Dostavljeno',
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => NotificationHelper.showInfo(context, 'Prikazivanje svih narudžbi'),
              child: const Text('Prikaži sve narudžbe'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build membership content
  Widget _buildMembershipContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_membership,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'PREMIUM ČLAN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Broj članske karte: MC-2020-001234',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMembershipStat('2020', 'Član od'),
                    _buildMembershipStat('5', 'Godina'),
                    _buildMembershipStat('Premium', 'Status'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Privilegije članstva',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildPrivilegeItem(Icons.discount, '20% popust na sve proizvode'),
          _buildPrivilegeItem(Icons.event_seat, 'Prioritet za rezervaciju sjedišta'),
          _buildPrivilegeItem(Icons.notifications, 'Ekskluzivne obavještenja'),
          _buildPrivilegeItem(Icons.sports_soccer, 'Besplatan pristup treninzima'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => NotificationHelper.showInfo(context, 'Obnavljanje članstva'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Obnovi članstvo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => NotificationHelper.showInfo(context, 'Upravljanje članstvom'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Upravljaj'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build membership stat item
  Widget _buildMembershipStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Build privilege item
  Widget _buildPrivilegeItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build ticket item
  Widget _buildTicketItem(
    BuildContext context,
    String match,
    String dateTime,
    String seatInfo,
    IconData icon,
    Color color, {
    bool isUsed = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUsed ? Colors.grey[100] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isUsed ? Colors.grey[300]! : color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isUsed ? Colors.grey : color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 14),
                    fontWeight: FontWeight.w600,
                    color: isUsed ? Colors.grey[600] : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 12),
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seatInfo,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isUsed)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  /// Build order item
  Widget _buildOrderItem(
    BuildContext context,
    String orderNumber,
    String price,
    String product,
    String date,
    IconData icon,
    Color color,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderNumber,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 12),
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle edit profile action
  void _handleEditProfile(BuildContext context) {
    NotificationHelper.showInfo(context, 'Otvaranje stranice za uređivanje profila');
    // TODO: Navigate to edit profile screen
  }

  /// Handle deactivate profile action
  void _handleDeactivateProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deaktivacija profila'),
          content: const Text(
            'Da li ste sigurni da želite deaktivirati svoj profil? Ova akcija se može poništiti kontaktiranjem podrške.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                NotificationHelper.showInfo(context, 'Profil je deaktiviran');
                // TODO: Implement profile deactivation logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deaktiviraj'),
            ),
          ],
        );
      },
    );
  }
}
