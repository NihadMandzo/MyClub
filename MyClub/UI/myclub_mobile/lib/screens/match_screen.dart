import 'package:flutter/material.dart';
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:provider/provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../providers/match_provider.dart';
import '../models/responses/match_response.dart';
import '../widgets/match_dialog.dart';

/// Match screen displaying results and schedule
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late MatchProvider _matchProvider;
  bool _isLoading = false;
  PagedResult<MatchResponse> _pastMatches = PagedResult();
  PagedResult<MatchResponse> _upcomingMatches = PagedResult();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _matchProvider = Provider.of<MatchProvider>(context, listen: false);
    _matchProvider.setContext(context);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pastMatches = await _matchProvider.getPastMatches();
      final upcomingMatchesResult = await _matchProvider.getUpcomingMatches();
      
      setState(() {
        _pastMatches = pastMatches;
        _upcomingMatches = upcomingMatchesResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        NotificationHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar with "Rezultati" and "Raspored"
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
              Tab(text: 'Rezultati'),
              Tab(text: 'Raspored'),
            ],
          ),
        ),
        
        // Separator line
        Container(
          height: 1,
          margin: ResponsiveHelper.pagePadding(context),
          color: Colors.grey[300],
        ),
        
        // Tab content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResultsTab(),
                    _buildScheduleTab(),
                  ],
                ),
        ),
      ],
    );
  }

  /// Build results tab (past matches with scores)
  Widget _buildResultsTab() {
  final pastMatchesList = _pastMatches.result ?? [];
    if (pastMatchesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nema završenih utakmica',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.pagePadding(context),
      itemCount: pastMatchesList.length,
      itemBuilder: (context, index) {
        final match = pastMatchesList[index];
        return _buildResultCard(match);
      },
    );
  }

  /// Build schedule tab (upcoming matches)
  Widget _buildScheduleTab() {
    final upcomingMatchesList = _upcomingMatches.result ?? [];
    
    if (upcomingMatchesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nema zakazanih utakmica',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.pagePadding(context),
      itemCount: upcomingMatchesList.length,
      itemBuilder: (context, index) {
        final match = upcomingMatchesList[index];
        return _buildScheduleCard(match);
      },
    );
  }

  /// Format date to dd.MM.yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Format time to HH:mm format
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Build result card for past matches (with scores)
  Widget _buildResultCard(MatchResponse match) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.gridSpacing(context)),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: ResponsiveHelper.pagePadding(context),
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
                      _formatDate(match.matchDate),
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
                      _formatTime(match.matchDate),
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
                    // Home team (club)
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
                            match.clubName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${match.result?.homeGoals ?? 0} : ${match.result?.awayGoals ?? 0}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 24),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    
                    // Away team (opponent)
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
                            match.opponentName,
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
                      match.location,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build schedule card for upcoming matches (without scores)
  Widget _buildScheduleCard(MatchResponse match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        child: InkWell(
          onTap: () {
            MatchDialog.show(context, match);
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
                      _formatDate(match.matchDate),
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
                      _formatTime(match.matchDate),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Teams with VS
                Row(
                  children: [
                    // Home team (club)
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
                            match.clubName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    // Away team (opponent)
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
                            match.opponentName,
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
                      match.location,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
