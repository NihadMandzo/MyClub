import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../providers/user_membership_card_provider.dart';
import '../providers/order_provider.dart';
import '../models/responses/user.dart';
import '../models/responses/user_ticket_response.dart';
import '../models/responses/user_membership_card_response.dart';
import '../models/responses/order_response.dart';
import '../models/responses/order_item_response.dart';
import 'edit_profile_screen.dart';
import 'ticket_detail_screen.dart';
import 'login_screen.dart';

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
  bool _showAllTickets = false;
  User? _currentUser;
  bool _isLoading = true;
  List<UserTicketResponse> _allTickets = [];
  List<UserTicketResponse> _validTickets = [];
  bool _isLoadingTickets = false;
  List<UserMembershipCardResponse> _membershipCards = [];
  bool _isLoadingMembershipCards = false;
  List<OrderResponse> _orders = [];
  bool _isLoadingOrders = false;
  Set<int> _expandedOrderIds = {};

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

  Future<void> _loadTickets() async {
    if (_isLoadingTickets) return;

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      
      // Load valid tickets (upcoming = true)
      final validTickets = await matchProvider.getUserTickets(upcoming: true);
      
      // Load all tickets (upcoming = false)
      final allTickets = await matchProvider.getUserTickets(upcoming: false);
      
      setState(() {
        _validTickets = validTickets;
        _allTickets = allTickets;
        _isLoadingTickets = false;
      });
    } catch (e) {
      print('Error loading tickets: $e');
      setState(() {
        _isLoadingTickets = false;
      });
      
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju ulaznica: $e');
      }
    }
  }

  Future<void> _loadMembershipCards() async {
    if (_isLoadingMembershipCards) return;

    setState(() {
      _isLoadingMembershipCards = true;
    });

    try {
      final membershipProvider = Provider.of<UserMembershipCardProvider>(context, listen: false);
      
      final pagedResult = await membershipProvider.getUserMembershipCards();
      
      setState(() {
        _membershipCards = pagedResult.result ?? [];
        _isLoadingMembershipCards = false;
      });
    } catch (e) {
      print('Error loading membership cards: $e');
      setState(() {
        _isLoadingMembershipCards = false;
      });
      
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju članskih karata: $e');
      }
    }
  }

  Future<void> _loadOrders() async {
    if (_isLoadingOrders) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      final pagedResult = await orderProvider.getUserOrders();
      
      setState(() {
        _orders = pagedResult.result ?? [];
        _isLoadingOrders = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoadingOrders = false;
      });
      
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju narudžbi: $e');
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
                      onTap: () {
                        setState(() => _isTicketsExpanded = !_isTicketsExpanded);
                        if (_isTicketsExpanded && _allTickets.isEmpty) {
                          _loadTickets();
                        }
                      },
                      content: _buildTicketsContent(),
                    ),
                    const SizedBox(height: 16),
                    _buildExpandableCard(
                      context,
                      title: 'Moje narudžbe',
                      icon: Icons.shopping_bag,
                      color: Colors.green,
                      isExpanded: _isOrdersExpanded,
                      onTap: () {
                        setState(() => _isOrdersExpanded = !_isOrdersExpanded);
                        if (_isOrdersExpanded && _orders.isEmpty) {
                          _loadOrders();
                        }
                      },
                      content: _buildOrdersContent(),
                    ),
                    const SizedBox(height: 16),
                    _buildExpandableCard(
                      context,
                      title: 'Moje članstvo',
                      icon: Icons.card_membership,
                      color: Colors.purple,
                      isExpanded: _isMembershipExpanded,
                      onTap: () {
                        setState(() => _isMembershipExpanded = !_isMembershipExpanded);
                        if (_isMembershipExpanded && _membershipCards.isEmpty) {
                          _loadMembershipCards();
                        }
                      },
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
                _buildProfileStat(context, _validTickets.length.toString(), 'Ulaznica'),
                _buildProfileStat(context, _orders.length.toString(), 'Narudžbi'),
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
    if (_isLoadingTickets) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_allTickets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nemate kupljenih ulaznica',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final ticketsToShow = _showAllTickets ? _allTickets : _validTickets;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showAllTickets && _validTickets.isNotEmpty) ...[
            Text(
              'Važeće ulaznice',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...ticketsToShow.map((ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRealTicketItem(context, ticket),
            )),
          ] else if (_showAllTickets) ...[
            Text(
              'Sve ulaznice',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...ticketsToShow.map((ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRealTicketItem(context, ticket),
            )),
          ] else ...[
            Text(
              'Nema važećih ulaznica',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!_showAllTickets && _allTickets.length > _validTickets.length)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAllTickets = true),
                child: const Text('Prikaži prethodne'),
              ),
            )
          else if (_showAllTickets)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAllTickets = false),
                child: const Text('Prikaži samo važeće'),
              ),
            ),
        ],
      ),
    );
  }

  /// Build orders content
  Widget _buildOrdersContent() {
    if (_isLoadingOrders) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nemate narudžbi',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Separate active and completed orders
    final activeOrders = _orders.where((order) => order.isActive).toList();
    final completedOrders = _orders.where((order) => !order.isActive).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeOrders.isNotEmpty) ...[
            Text(
              'Aktivne narudžbe',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...activeOrders.map((order) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOrderItemFromData(context, order),
            )),
            const SizedBox(height: 16),
          ],
          if (completedOrders.isNotEmpty) ...[
            Text(
              'Prethodne narudžbe',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...completedOrders.take(3).map((order) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOrderItemFromData(context, order),
            )),
            if (completedOrders.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => NotificationHelper.showInfo(context, 'Prikazivanje svih narudžbi'),
                  child: const Text('Prikaži sve narudžbe'),
                ),
              ),
            ],
          ],
          if (activeOrders.isEmpty && completedOrders.isEmpty)
            Center(
              child: Text(
                'Nemate narudžbi',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build order item from OrderResponse data
  Widget _buildOrderItemFromData(BuildContext context, OrderResponse order) {
    final bool isExpanded = _expandedOrderIds.contains(order.id);
    Color color;
    IconData icon;
    
    switch (order.statusColor) {
      case 'green':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'orange':
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case 'blue':
        color = Colors.blue;
        icon = Icons.pending;
        break;
      case 'red':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.shopping_bag;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Main order info
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedOrderIds.remove(order.id);
                } else {
                  _expandedOrderIds.add(order.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: isExpanded 
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(8),
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
                              'Narudžba #${order.id.toString().padLeft(6, '0')}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${order.totalAmount.toStringAsFixed(2)} KM',
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
                          order.orderSummary,
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
                              order.formattedOrderDate,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 12),
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.orderState,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.expand_more,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded order items
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(
                  left: BorderSide(color: color.withOpacity(0.3)),
                  right: BorderSide(color: color.withOpacity(0.3)),
                  bottom: BorderSide(color: color.withOpacity(0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stavke narudžbe:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.orderItems.map((item) => _buildOrderItemDetail(context, item)),
                  const SizedBox(height: 8),
                  const Divider(),
                  // Order summary
                  if (order.shippingAddress.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Adresa: ${order.shippingAddress}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Način plaćanja: ${order.paymentMethod}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (order.hasMembershipDiscount) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.card_membership, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Popust za članove: ${order.discountAmount.toStringAsFixed(2)} KM',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 12),
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  /// Build individual order item detail
  Widget _buildOrderItemDetail(BuildContext context, OrderItemResponse item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 13),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Veličina: ${item.sizeName}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 11),
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Količina: ${item.quantity}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 11),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.unitPrice.toStringAsFixed(2)} KM',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)} KM',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build membership content
  Widget _buildMembershipContent() {
    if (_isLoadingMembershipCards) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_membershipCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nemate aktivnih članskih karata',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vaše članske karte',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ..._membershipCards.map((card) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMembershipCardItem(context, card),
          )),
        ],
      ),
    );
  }

  /// Build membership card item with user info overlay on the image
  Widget _buildMembershipCardItem(BuildContext context, UserMembershipCardResponse card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              // Background card image
              Positioned.fill(
                child: card.cardImageUrl.isNotEmpty
                    ? Image.network(
                        card.cardImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
              ),
              // Dark overlay for better text visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Card content with user info
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with membership card name and year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              card.membershipCardName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: card.isValid ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              card.year.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // User info at the bottom
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.userFullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Broj članske karte: ${card.membershipNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Član od: ${card.formattedJoinDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  Text(
                                    'Važi do: ${card.formattedValidUntil}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                              if (card.isValid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'AKTIVNA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ISTEKLA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // QR Code icon in top right corner
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _showQRCode(context, card),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show QR code dialog
  void _showQRCode(BuildContext context, UserMembershipCardResponse card) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = ResponsiveHelper.deviceSize(context) == DeviceSize.small;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: isSmallDevice ? 320 : 350,
            constraints: BoxConstraints(
              maxWidth: isSmallDevice ? 320 : 350,
              maxHeight: screenHeight * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: ResponsiveHelper.pagePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code, 
                          color: Theme.of(context).primaryColor,
                          size: ResponsiveHelper.iconSize(context),
                        ),
                        SizedBox(width: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8),
                        Text(
                          'QR Kod',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallDevice ? 16 : 24),
                    
                    // QR Code
                    Container(
                      width: isSmallDevice ? 150 : 180,
                      height: isSmallDevice ? 150 : 180,
                      padding: EdgeInsets.all(isSmallDevice ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: card.qrCodeData.isNotEmpty
                          ? QrImageView(
                              data: card.qrCodeData,
                              version: QrVersions.auto,
                              size: isSmallDevice ? 134.0 : 164.0,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            )
                          : Center(
                              child: Text(
                                'Nema QR koda',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.font(context, base: 16),
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                    
                    SizedBox(height: isSmallDevice ? 16 : 20),
                    
                    // Membership card info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallDevice ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            card.membershipCardName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallDevice ? 6 : 8),
                          Text(
                            card.userFullName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 14),
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallDevice ? 3 : 4),
                          Text(
                            'Broj: ${card.membershipNumber}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 12),
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmallDevice ? 12 : 16),
                    
                    // Instructions
                    Text(
                      'Pokažite ovaj QR kod na ulazu ili bilo kojem mjestu gdje je potrebna verifikacija članstva',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: isSmallDevice ? 16 : 20),
                    
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: ResponsiveHelper.iconSize(context) * 0.8,
                        ),
                        label: Text(
                          'Zatvori',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallDevice ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build real ticket item from API data
  Widget _buildRealTicketItem(BuildContext context, UserTicketResponse ticket) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TicketDetailScreen(ticket: ticket),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ticket.isValid ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ticket.isValid ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sports_soccer,
              color: ticket.isValid ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.opponentName,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 14),
                      fontWeight: FontWeight.w600,
                      color: ticket.isValid ? null : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.formattedMatchDate,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 12),
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.seatInfo,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ticket.totalPrice.toStringAsFixed(2)} KM',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 12),
                    fontWeight: FontWeight.bold,
                    color: ticket.isValid ? Colors.blue : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (!ticket.isValid)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VAŽEĆA',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 8),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle edit profile action
  void _handleEditProfile(BuildContext context) async {
    if (_currentUser == null) {
      NotificationHelper.showError(context, 'Korisničke podatke nije moguće učitati');
      return;
    }

    final updatedUser = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
      NotificationHelper.showSuccess(context, 'Profil je uspješno ažuriran');
    }
  }

  /// Handle deactivate profile action
  void _handleDeactivateProfile(BuildContext context) async {
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDeactivation();
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

  /// Perform the actual deactivation
  Future<void> _performDeactivation() async {
    // Store context references before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Call deactivation endpoint
      await userProvider.deactivateAccount();

      // Close loading dialog - use stored navigator
      navigator.pop();
      
      // Show success message using ScaffoldMessenger instead of NotificationHelper
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profil je uspješno deaktiviran'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear all authentication data and logout
      await authProvider.logout();
      
      // Navigate to login screen by replacing all routes
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      print('Error deactivating profile: $e');
      
      // Close loading dialog if still open - use stored navigator
      try {
        navigator.pop();
      } catch (navError) {
        print('Navigation error while closing dialog: $navError');
      }
      
      // Show error message using ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Greška pri deaktivaciji profila: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
