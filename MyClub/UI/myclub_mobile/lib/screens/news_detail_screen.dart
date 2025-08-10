import 'package:flutter/material.dart';
import '../models/responses/news_response.dart';
import '../models/responses/asset_response.dart';
import '../utility/responsive_helper.dart';
import '../widgets/comments_widget.dart';
import '../widgets/horizontal_image_gallery.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsResponse news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsResponse _news;

  @override
  void initState() {
    super.initState();
    _news = widget.news;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vijest'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewsHeader(),
            const SizedBox(height: 16),
            _buildNewsImages(),
            const SizedBox(height: 16),
            _buildNewsContent(),
            const SizedBox(height: 24),
            _buildCommentsButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _news.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 24),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Date and author info
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: ResponsiveHelper.font(context, base: 16),
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '${_news.date.day.toString().padLeft(2, '0')}.${_news.date.month.toString().padLeft(2, '0')}.${_news.date.year}',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey.shade600,
              ),
            ),
            if (_news.username.isNotEmpty) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.person,
                size: ResponsiveHelper.font(context, base: 16),
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _news.username,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNewsImages() {
    // Combine primary image and additional images
    List<AssetResponse> allImages = [];
  
    // Add additional images
    allImages.addAll(_news.images);
    
    // If no images, return empty widget
    if (allImages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Use horizontal image gallery
    return HorizontalImageGallery(
      images: allImages,
      height: 250,
    );
  }

  Widget _buildNewsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content
        Text(
          _news.content,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            color: Colors.black87,
            height: 1.6,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Media indicators
        if (_news.videoUrl != null && _news.videoUrl!.isNotEmpty)
          _buildVideoIndicator(),
      ],
    );
  }

  Widget _buildVideoIndicator() {
    if (_news.videoUrl == null || _news.videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: ResponsiveHelper.font(context, base: 16),
            color: Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            'Video priložen',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 12),
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsButton() {
    final commentsCount = _news.comments.length;
    final buttonText = commentsCount > 0 
        ? 'Pogledaj komentare ($commentsCount)'
        : 'Dodaj komentar';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCommentsDialog(),
        icon: Icon(
          commentsCount > 0 ? Icons.comment : Icons.add_comment,
          size: ResponsiveHelper.iconSize(context),
        ),
        label: Text(
          buttonText,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CommentsWidget(
        comments: _news.comments,
        onCommentAdded: (comment) {
          setState(() {
            _news.comments.add(comment);
          });
        },
        onCommentUpdated: (updatedComment) {
          setState(() {
            final index = _news.comments.indexWhere((c) => c.id == updatedComment.id);
            if (index != -1) {
              _news.comments[index] = updatedComment;
            }
          });
        },
        onCommentDeleted: (comment) {
          setState(() {
            _news.comments.remove(comment);
          });
        },
      ),
    );
  }
}
