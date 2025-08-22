import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/membership_provider.dart';
import '../providers/news_provider.dart';
import '../models/responses/membership_card.dart';
import '../models/responses/news_response.dart';
import '../models/responses/paged_result.dart';
import '../models/search_objects/base_search_object.dart';
import '../utility/responsive_helper.dart';
import '../widgets/pagination_widget.dart';
import '../screens/news_detail_screen.dart';
import '../screens/membership_purchase_screen.dart';

/// Home screen with responsive layout and example content
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;
  MembershipCard? _currentMembership;
  bool _isLoading = true;
  
  // News related state
  final TextEditingController _searchController = TextEditingController();
  PagedResult<NewsResponse>? _newsResult;
  bool _isLoadingNews = false;
  bool _showSearchBar = false;
  int _currentPage = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembershipData();
    _startAutoRefresh();
    _loadNews();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadMembershipData();
    });
  }

  Future<void> _loadMembershipData() async {
    if (!mounted) return;
    
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    membershipProvider.setContext(context);
    
    try {
      final membership = await membershipProvider.getCurrentMembership();
      if (mounted) {
        setState(() {
          _currentMembership = membership;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentMembership = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNews({String? searchQuery, int page = 0}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingNews = true;
    });

    try {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.setContext(context);

      final searchObject = BaseSearchObject(
        fts: searchQuery?.isNotEmpty == true ? searchQuery : null,
        page: page,
        pageSize: 5,
      );

      final result = await newsProvider.get(searchObject: searchObject);

      if (mounted) {
        setState(() {
          _newsResult = result;
          _currentPage = page;
          _searchQuery = searchQuery ?? '';
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška prilikom učitavanja vijesti: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        if (_searchQuery.isNotEmpty) {
          _loadNews(); // Reload without search
        }
      }
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    _loadNews(searchQuery: query, page: 0);
  }

  void _onPageChanged(int page) {
    _loadNews(searchQuery: _searchQuery, page: page);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMembershipCard(context),
          const SizedBox(height: 32),
          _buildNewsSection(context),
        ],
      ),
    );
  }

  /// Build simplified membership card with current membership stats
  Widget _buildMembershipCard(BuildContext context) {
    if (_isLoading) {
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
            gradient: const LinearGradient(
              colors: [
                Colors.blue,
                Color(0xFF1976D2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_currentMembership == null) {
      return Card(
        elevation: ResponsiveHelper.cardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToMembershipPurchase(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Colors.blue,
                  Color(0xFF1976D2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Nema aktivnog članstva',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Postani član',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 12),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Text(
                  '0 / 0 članova',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 14),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final membership = _currentMembership!;
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToMembershipPurchase(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Colors.blue,
                Color(0xFF1976D2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      membership.name,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Kupi sada',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: membership.membershipProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                membership.progressText,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build news section with search and pagination
  Widget _buildNewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNewsSectionHeader(),
        const SizedBox(height: 16),
        if (_showSearchBar) ...[
          _buildNewsSearchBar(),
          const SizedBox(height: 16),
        ],
        _buildNewsContent(),
      ],
    );
  }

  Widget _buildNewsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Vijesti',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 20),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: _toggleSearchBar,
          icon: Icon(
            _showSearchBar ? Icons.close : Icons.search,
            size: ResponsiveHelper.iconSize(context),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži vijesti...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: ResponsiveHelper.font(context, base: 14),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          IconButton(
            onPressed: _performSearch,
            icon: Icon(
              Icons.search,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsContent() {
    if (_isLoadingNews && _newsResult == null) {
      return _buildNewsLoadingIndicator();
    }

    if (_newsResult == null || _newsResult!.result == null || _newsResult!.result!.isEmpty) {
      return _buildNewsEmptyState();
    }

    final totalPages = (_newsResult!.totalPages ?? 0).clamp(1, 999);

    return Column(
      children: [
        // News list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _newsResult!.result!.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final news = _newsResult!.result![index];
            return _buildNewsCard(news);
          },
        ),

        const SizedBox(height: 16),

        // Pagination
        if (totalPages > 1)
          PaginationWidget(
            currentPage: _currentPage,
            totalPages: totalPages,
            currentPageSize: 10, // Default value, not shown since showPageSizeSelector is false
            onPageChanged: _onPageChanged,
            isLoading: _isLoadingNews,
            showPageNumbers: false,
            showPageSizeSelector: false, // Hide page size selector in home screen
          ),
      ],
    );
  }

  Widget _buildNewsCard(NewsResponse news) {
    final isSmallDevice = ResponsiveHelper.deviceSize(context) == DeviceSize.small;
    final imageSize = isSmallDevice ? 70.0 : 80.0;

    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onNewsCardTapped(news),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News image
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: news.primaryImage != null && news.primaryImage!.imageUrl.isNotEmpty
                      ? Image.network(
                          news.primaryImage!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildNewsPlaceholderImage();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : _buildNewsPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 10),
              
              // News content
              Expanded(
                child: _buildNewsCardContent(news),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.article_outlined,
        size: 32,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildNewsCardContent(NewsResponse news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          news.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 14),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 6),
        
        // Date and author in a more compact layout
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: ResponsiveHelper.font(context, base: 12),
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '${news.date.day.toString().padLeft(2, '0')}.${news.date.month.toString().padLeft(2, '0')}.${news.date.year}',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 11),
                color: Colors.grey.shade600,
              ),
            ),
            if (news.username.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.person_outline,
                size: ResponsiveHelper.font(context, base: 12),
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  news.username,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 11),
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Comments and media indicators (moved up, removed content preview)
        Row(
          children: [
            if (news.comments.isNotEmpty) ...[
              Icon(
                Icons.comment_outlined,
                size: ResponsiveHelper.font(context, base: 12),
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                '${news.comments.length}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 10),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (news.videoUrl != null && news.videoUrl!.isNotEmpty) ...[
              if (news.comments.isNotEmpty) const SizedBox(width: 8),
              Icon(
                Icons.play_circle_outline,
                size: ResponsiveHelper.font(context, base: 12),
                color: Colors.blue,
              ),
            ],
            if (news.images.isNotEmpty) ...[
              if (news.comments.isNotEmpty || (news.videoUrl != null && news.videoUrl!.isNotEmpty))
                const SizedBox(width: 8),
              Icon(
                Icons.photo_library_outlined,
                size: ResponsiveHelper.font(context, base: 12),
                color: Colors.green,
              ),
              const SizedBox(width: 2),
              Text(
                '${news.images.length}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 10),
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNewsLoadingIndicator() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Učitavanje vijesti...',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Nema vijesti za pretragu "$_searchQuery"'
                : 'Nema dostupnih vijesti',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _loadNews();
              },
              child: const Text('Prikaži sve vijesti'),
            ),
          ],
        ],
      ),
    );
  }

  void _onNewsCardTapped(NewsResponse news) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
  }

  void _navigateToMembershipPurchase() {
    if (_currentMembership != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MembershipPurchaseScreen(
            membershipCard: _currentMembership!,
          ),
        ),
      );
    } else {
      // Show message to create membership campaign first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trenutno nema dostupnih kampanja za članstvo'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
