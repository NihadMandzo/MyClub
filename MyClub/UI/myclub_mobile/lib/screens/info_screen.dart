import 'package:flutter/material.dart';
import 'package:myclub_mobile/models/responses/club_response.dart';
import 'package:myclub_mobile/providers/club_provider.dart';
import 'package:provider/provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../providers/player_provider.dart';
import '../providers/membership_provider.dart';
import '../models/responses/player_response.dart';
import '../models/responses/membership_card.dart';
import '../screens/membership_purchase_screen.dart';

/// Info screen with various options and club information
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  bool _isPlayersExpanded = false;
  bool _isMembershipExpanded = false;
  late TabController _tabController;
  List<PlayerResponse> _players = [];
  List<PlayerResponse> _coachingStaff = [];
  MembershipCard? _currentMembership;
  ClubResponse? _clubInfo;
  bool _isLoading = false;
  bool _isMembershipLoading = false;
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayers();
    _loadClubInfo();
  }

  void _loadClubInfo() {
    ClubProvider().getById(1).then((clubInfo) {
      setState(() {
        _clubInfo = clubInfo;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      final allPlayers = await playerProvider.getPlayers();

      if (mounted) {
        setState(() {
          _players = allPlayers
              .where((player) => player.position.isPlayer)
              .toList();
          _coachingStaff = allPlayers
              .where((player) => player.position.isPlayer == false)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationHelper.showApiError(context, e, 'učitavanju tima');
      }
    }
  }

  Future<void> _loadCurrentMembership() async {
    if (!mounted) return;

    setState(() {
      _isMembershipLoading = true;
    });

    try {
      final membershipProvider = Provider.of<MembershipProvider>(
        context,
        listen: false,
      );
      final membership = await membershipProvider.getCurrentMembership();

      if (mounted) {
        setState(() {
          _currentMembership = membership;
          _isMembershipLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMembershipLoading = false;
        });
        NotificationHelper.showApiError(context, e, 'učitavanju članstva');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClubInfoCard(context),
          const SizedBox(height: 20),
          _buildExpandableCard(
            context,
            title: 'Članstvo',
            icon: Icons.card_membership,
            color: Colors.green,
            isExpanded: _isMembershipExpanded,
            onTap: () {
              setState(() {
                _isMembershipExpanded = !_isMembershipExpanded;
              });
              if (_isMembershipExpanded &&
                  _currentMembership == null &&
                  !_isMembershipLoading) {
                _loadCurrentMembership();
              }
            },
            content: _buildMembershipContent(),
          ),
          const SizedBox(height: 20),
          _buildExpandableCard(
            context,
            title: 'Tim',
            icon: Icons.sports_soccer,
            color: Colors.blue,
            isExpanded: _isPlayersExpanded,
            onTap: () {
              setState(() {
                _isPlayersExpanded = !_isPlayersExpanded;
              });
              if (_isPlayersExpanded &&
                  _players.isEmpty &&
                  _coachingStaff.isEmpty) {
                _loadPlayers();
              }
            },
            content: _buildPlayersContent(),
          ),
        ],
      ),
    );
  }

  /// Build expandable card widget
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
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
            onTap: onTap,
          ),
          if (isExpanded) ...[const Divider(height: 1), content],
        ],
      ),
    );
  }

  /// Build membership content
  Widget _buildMembershipContent() {
    if (_isMembershipLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentMembership == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Trenutno nema aktivnih kampanja za članstvo',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildMembershipCard(_currentMembership!);
  }

  /// Build membership card widget
  Widget _buildMembershipCard(MembershipCard membership) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membership card image and header
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Background image
                if (membership.imageUrl != null &&
                    membership.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      membership.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container();
                      },
                    ),
                  ),
                // Overlay with gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Content overlay
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${membership.year}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: membership.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              membership.isActive ? 'Aktivno' : 'Neaktivno',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Bottom section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            membership.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${membership.price.toStringAsFixed(2)} KM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Membership details
          if (membership.description != null &&
              membership.description!.isNotEmpty) ...[
            Text(
              'Opis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(membership.description!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
          ],

          // Benefits
          if (membership.benefits != null &&
              membership.benefits!.isNotEmpty) ...[
            Text(
              'Benefiti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(membership.benefits!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
          ],

          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Napredak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          membership.progressText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: membership.membershipProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Become member button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _becomeMember(membership),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Postani član',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Handle become member action
  void _becomeMember(MembershipCard membership) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MembershipPurchaseScreen(
          membershipCard: membership,
        ),
      ),
    );
  }

  /// Build players content with tabs
  Widget _buildPlayersContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: 'Igrači'),
              Tab(text: 'Stručni štab'),
            ],
          ),
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPlayersList(_players),
              _buildPlayersList(_coachingStaff),
            ],
          ),
        ),
      ],
    );
  }

  /// Build players list
  Widget _buildPlayersList(List<PlayerResponse> players) {
    if (players.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Nema podataka'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _buildPlayerCard(player);
      },
    );
  }

  /// Build individual player card
  Widget _buildPlayerCard(PlayerResponse player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          radius: 25,
          child: player.imageUrl != null && player.imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    player.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Theme.of(context).primaryColor,
                        child: Center(
                          child: Text(
                            player.number.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        color: Theme.of(context).primaryColor,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  player.number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        title: Text(
          player.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.position.name,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              '${player.age} godina • ${player.nationality.name}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showPlayerDetails(player),
      ),
    );
  }

  /// Show player details dialog
  void _showPlayerDetails(PlayerResponse player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player image
              if (player.imageUrl != null && player.imageUrl!.isNotEmpty) ...[
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        player.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Player details
              _buildDetailRow('Pozicija', player.position.name),
              _buildDetailRow('Broj', player.number.toString()),
              _buildDetailRow('Godine', player.age.toString()),
              _buildDetailRow('Nacionalnost', player.nationality.name),
              _buildDetailRow('Visina', '${player.height}cm'),
              _buildDetailRow('Težina', '${player.weight}kg'),
              if (player.dateOfBirth != null) ...[
                _buildDetailRow(
                  'Datum rođenja',
                  '${player.dateOfBirth!.day}.${player.dateOfBirth!.month}.${player.dateOfBirth!.year}',
                ),
              ],
              if (player.biography != null && player.biography!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Biografija:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(player.biography!, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  /// Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Build club information card
  Widget _buildClubInfoCard(BuildContext context) {
    // Show loading state if club info is not loaded yet
    if (_clubInfo == null) {
      return Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: Container(
          width: double.infinity,
          height: 300,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: ResponsiveHelper.iconSize(context) + 20,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Učitavanje informacija o klubu...',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Club header with logo and basic info
            Row(
              children: [
                // Club logo
                if (_clubInfo?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _clubInfo!.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sports_soccer,
                            size: 30,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clubInfo?.name ?? 'N/A',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Osnovan ${_clubInfo?.establishedDate?.year ?? 'N/A'}.',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 14),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stadium information
            if (_clubInfo?.stadiumName != null || _clubInfo?.stadiumLocation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stadium,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_clubInfo?.stadiumName != null)
                            Text(
                              _clubInfo!.stadiumName!,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 14),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          if (_clubInfo?.stadiumLocation != null)
                            Text(
                              _clubInfo!.stadiumLocation!,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 12),
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            if (!_isCardExpanded) ...[
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    context, 
                    _clubInfo?.establishedDate != null 
                      ? '${DateTime.now().year - _clubInfo!.establishedDate!.year}' 
                      : 'N/A', 
                    'Godine'
                  ),
                  _buildStatItem(context, '${_clubInfo?.numberOfTitles ?? 0}', 'Trofeji'),
                ],
              ),
            ],
            
            if (_isCardExpanded) ...[
              const SizedBox(height: 16),
              // Expanded content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row in expanded view
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context, 
                          _clubInfo?.establishedDate != null 
                            ? '${DateTime.now().year - _clubInfo!.establishedDate!.year}' 
                            : 'N/A', 
                          'Godine'
                        ),
                        _buildStatItem(context, '${_clubInfo?.numberOfTitles ?? 0}', 'Trofeji'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    if (_clubInfo?.description != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'O klubu',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _clubInfo!.description,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 14),
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            // Expand/Collapse button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCardExpanded = !_isCardExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isCardExpanded ? 'Prikaži manje' : 'Prikaži više',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isCardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
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
}
