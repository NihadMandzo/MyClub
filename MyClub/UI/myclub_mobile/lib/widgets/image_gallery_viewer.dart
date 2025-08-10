import 'package:flutter/material.dart';
import '../models/responses/asset_response.dart';
import '../utility/responsive_helper.dart';

class ImageGalleryViewer extends StatefulWidget {
  final List<AssetResponse> images;
  final int initialIndex;

  const ImageGalleryViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} od ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Image PageView
          GestureDetector(
            onTap: () {
              // Reset zoom on single tap if zoomed
              if (_isZoomed) {
                _transformationController.value = Matrix4.identity();
                setState(() {
                  _isZoomed = false;
                });
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              physics: _isZoomed ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                // Reset zoom when changing images
                _transformationController.value = Matrix4.identity();
                _isZoomed = false;
              },
              itemBuilder: (context, index) {
                return _buildZoomableImage(widget.images[index]);
              },
            ),
          ),

          // Bottom overlay with dots indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildDotsIndicator(),
            ),

          // Zoom instructions overlay
          Positioned(
            bottom: widget.images.length > 1 ? 100 : 40,
            left: 20,
            right: 20,
            child: _buildInstructionsOverlay(),
          ),

          // Zoom state indicator
          if (_isZoomed)
            Positioned(
              top: 100,
              right: 20,
              child: _buildZoomIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomableImage(AssetResponse image) {
    return Center(
      child: GestureDetector(
        onDoubleTap: () => _handleDoubleTap(),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          onInteractionStart: (details) {
            // Store initial scale to detect zoom changes
          },
          onInteractionEnd: (details) {
            // Check if image is zoomed
            final scale = _transformationController.value.getMaxScaleOnAxis();
            setState(() {
              _isZoomed = scale > 1.0;
            });
          },
          child: Image.network(
            image.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey.shade900,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Greška pri učitavanju slike',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: ResponsiveHelper.font(context, base: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Učitavanje slike...',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: ResponsiveHelper.font(context, base: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.images.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 12 : 8,
            height: _currentIndex == index ? 12 : 8,
            decoration: BoxDecoration(
              color: _currentIndex == index 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsOverlay() {
    return AnimatedOpacity(
      opacity: _isZoomed ? 0.0 : 0.7,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Dvaput dodirnite za zumiranje • Štipanje za zumiranje',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: ResponsiveHelper.font(context, base: 12),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.zoom_in,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${(scale * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _transformationController.value = Matrix4.identity();
              setState(() {
                _isZoomed = false;
              });
            },
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDoubleTap() {
    const double zoomScale = 2.0;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    
    if (currentScale > 1.0) {
      // Zoom out to fit
      _transformationController.value = Matrix4.identity();
      setState(() {
        _isZoomed = false;
      });
    } else {
      // Zoom in to 2x
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final center = Offset(size.width / 2, size.height / 2);
      
      _transformationController.value = Matrix4.identity()
        ..translate(center.dx, center.dy)
        ..scale(zoomScale)
        ..translate(-center.dx, -center.dy);
      
      setState(() {
        _isZoomed = true;
      });
    }
  }

  
}
