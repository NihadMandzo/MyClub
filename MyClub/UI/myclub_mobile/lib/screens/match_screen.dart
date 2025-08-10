import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';

/// Match screen displaying upcoming and past matches
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: ResponsiveHelper.pagePadding(context),
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
              Tab(text: 'Predstojеće'),
              Tab(text: 'Prošle'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingMatches(),
              _buildPastMatches(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build upcoming matches tab
  Widget _buildUpcomingMatches() {
    final upcomingMatches = _getMockUpcomingMatches();
    
    return ListView.builder(
      padding: ResponsiveHelper.pagePadding(context),
      itemCount: upcomingMatches.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddMatchButton();
        }
        
        final match = upcomingMatches[index - 1];
        return _buildMatchCard(match, isUpcoming: true);
      },
    );
  }

  /// Build past matches tab
  Widget _buildPastMatches() {
    final pastMatches = _getMockPastMatches();
    
    return ListView.builder(
      padding: ResponsiveHelper.pagePadding(context),
      itemCount: pastMatches.length,
      itemBuilder: (context, index) {
        final match = pastMatches[index];
        return _buildMatchCard(match, isUpcoming: false);
      },
    );
  }

  /// Build add match button
  Widget _buildAddMatchButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: InkWell(
          onTap: () {
            NotificationHelper.showInfo(context, 'Dodavanje nove utakmice...');
            // TODO: Navigate to add match screen
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dodaj novu utakmicu',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 16),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build individual match card
  Widget _buildMatchCard(Map<String, dynamic> match, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: InkWell(
          onTap: () {
            NotificationHelper.showInfo(context, 'Otvaranje detalja utakmice...');
            // TODO: Navigate to match details
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match['date'],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match['time'],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Teams and score
                Row(
                  children: [
                    // Home team
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: ResponsiveHelper.iconSize(context) + 8,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match['homeTeam'],
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Score or VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: isUpcoming
                          ? Text(
                              'VS',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 18),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            )
                          : Text(
                              '${match['homeScore']} : ${match['awayScore']}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 24),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                    ),
                    
                    // Away team
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: ResponsiveHelper.iconSize(context) + 8,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match['awayTeam'],
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match['location'],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Status for upcoming matches
                if (isUpcoming) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Potvrđeno',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get mock upcoming matches data
  List<Map<String, dynamic>> _getMockUpcomingMatches() {
    return [
      {
        'date': '15. Aug 2025',
        'time': '18:00',
        'homeTeam': 'MyClub',
        'awayTeam': 'FK Sarajevo',
        'location': 'Stadion MyClub',
      },
      {
        'date': '22. Aug 2025',
        'time': '20:00',
        'homeTeam': 'FK Željezničar',
        'awayTeam': 'MyClub',
        'location': 'Grbavica',
      },
      {
        'date': '28. Aug 2025',
        'time': '16:00',
        'homeTeam': 'MyClub',
        'awayTeam': 'FK Sloboda',
        'location': 'Stadion MyClub',
      },
    ];
  }

  /// Get mock past matches data
  List<Map<String, dynamic>> _getMockPastMatches() {
    return [
      {
        'date': '5. Aug 2025',
        'time': '18:00',
        'homeTeam': 'MyClub',
        'awayTeam': 'FK Tuzla City',
        'homeScore': 2,
        'awayScore': 1,
        'location': 'Stadion MyClub',
      },
      {
        'date': '30. Jul 2025',
        'time': '20:00',
        'homeTeam': 'FK Borac',
        'awayTeam': 'MyClub',
        'homeScore': 0,
        'awayScore': 3,
        'location': 'Gradski stadion',
      },
      {
        'date': '22. Jul 2025',
        'time': '17:00',
        'homeTeam': 'MyClub',
        'awayTeam': 'FK Velež',
        'homeScore': 1,
        'awayScore': 1,
        'location': 'Stadion MyClub',
      },
    ];
  }
}
