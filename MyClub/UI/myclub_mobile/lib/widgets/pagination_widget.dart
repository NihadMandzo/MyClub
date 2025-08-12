import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int currentPageSize;
  final Function(int) onPageChanged;
  final Function(int)? onPageSizeChanged;
  final bool isLoading;
  final bool showPageNumbers;
  final bool showPageSizeSelector;
  final List<int> pageSizeOptions;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.currentPageSize,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.isLoading = false,
    this.showPageNumbers = true,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [6, 12, 24, 48],
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12, 
        horizontal: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 4 : 8
      ),
      child: Column(
        children: [
          // Page size selector (top on small screens, left on larger screens)
          if (showPageSizeSelector && onPageSizeChanged != null && isSmallScreen) ...[
            _buildPageSizeSelector(context),
            const SizedBox(height: 8),
          ],
          
          // Navigation controls
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Page size selector (left side on larger screens)
                if (showPageSizeSelector && onPageSizeChanged != null && !isSmallScreen) ...[
                  _buildPageSizeSelector(context),
                  const SizedBox(width: 8),
                ],
                
                // Previous button
                IconButton(
                  onPressed: currentPage > 0 && !isLoading
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: currentPage > 0 && !isLoading
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    foregroundColor: currentPage > 0 && !isLoading
                        ? Colors.white
                        : Colors.grey.shade600,
                    minimumSize: Size(
                      isSmallScreen ? 28 : 32, 
                      isSmallScreen ? 28 : 32
                    ),
                  ),
                ),
                
                // Page indicators (only show if showPageNumbers is true)
                if (showPageNumbers) ...[
                  const SizedBox(width: 4),
                  // Use Flexible to allow page buttons to take remaining space
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildPageButtons(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                
                // Next button
                IconButton(
                  onPressed: currentPage < totalPages - 1 && !isLoading
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: currentPage < totalPages - 1 && !isLoading
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    foregroundColor: currentPage < totalPages - 1 && !isLoading
                        ? Colors.white
                        : Colors.grey.shade600,
                    minimumSize: Size(
                      isSmallScreen ? 28 : 32, 
                      isSmallScreen ? 28 : 32
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPageSizeSelector(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isVerySmall) ...[
          Text(
            'Po stranici:',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 12),
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          constraints: BoxConstraints(
            minWidth: isVerySmall ? 40 : 50, // Ensure minimum width
          ),
          padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 4 : 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: currentPageSize,
              isExpanded: false,
              isDense: isVerySmall,
              items: pageSizeOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: isVerySmall ? 10 : 12),
                    ),
                  ),
                );
              }).toList(),
              onChanged: isLoading 
                  ? null 
                  : (int? value) {
                      if (value != null) {
                        onPageSizeChanged!(value);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageButtons(BuildContext context) {
    List<Widget> buttons = [];
    
    if (totalPages <= 0) return buttons;
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine how many pages to show based on screen size
    // Be more conservative to prevent overflow
    int maxVisiblePages;
    if (screenWidth < 360) {
      maxVisiblePages = 3; // Very small screens: current + 2 others max
    } else if (screenWidth < 600) {
      maxVisiblePages = 5; // Small to medium screens
    } else {
      maxVisiblePages = 7; // Large screens
    }
    
    // If total pages fit within max visible, show all
    if (totalPages <= maxVisiblePages) {
      for (int i = 0; i < totalPages; i++) {
        buttons.add(_buildPageButton(context, i));
      }
      return buttons;
    }
    
    // For many pages, use a more space-efficient approach
    // Calculate available "slots" considering ellipsis take space too
    int availableSlots = maxVisiblePages - 2; // Reserve 2 for potential ellipsis
    
    // Always show first page
    buttons.add(_buildPageButton(context, 0));
    
    // Determine if we need ellipsis and how many pages to show around current
    bool needStartEllipsis = currentPage > 2;
    bool needEndEllipsis = currentPage < totalPages - 3;
    
    if (needStartEllipsis && needEndEllipsis) {
      // Both ellipsis needed - show minimal range around current
      buttons.add(_buildEllipsis(context));
      
      // Show only current page and maybe 1 neighbor on each side for very small screens
      int sidePages = screenWidth < 360 ? 0 : 1;
      int start = (currentPage - sidePages).clamp(1, totalPages - 2);
      int end = (currentPage + sidePages).clamp(1, totalPages - 2);
      
      for (int i = start; i <= end; i++) {
        buttons.add(_buildPageButton(context, i));
      }
      
      buttons.add(_buildEllipsis(context));
    } else if (needStartEllipsis) {
      // Only start ellipsis needed
      buttons.add(_buildEllipsis(context));
      
      // Show more pages at the end
      int startPage = (totalPages - availableSlots + 1).clamp(1, totalPages - 1);
      for (int i = startPage; i < totalPages - 1; i++) {
        buttons.add(_buildPageButton(context, i));
      }
    } else if (needEndEllipsis) {
      // Only end ellipsis needed
      // Show more pages at the beginning
      for (int i = 1; i < availableSlots; i++) {
        buttons.add(_buildPageButton(context, i));
      }
      
      buttons.add(_buildEllipsis(context));
    } else {
      // No ellipsis needed, show consecutive pages
      for (int i = 1; i < totalPages - 1; i++) {
        buttons.add(_buildPageButton(context, i));
      }
    }
    
    // Always show last page (if more than 1 page total)
    if (totalPages > 1) {
      buttons.add(_buildPageButton(context, totalPages - 1));
    }
    
    return buttons;
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final isCurrentPage = page == currentPage;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth < 360 ? 28.0 : 32.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 0.25 : 0.5), // Reduced padding
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: TextButton(
          onPressed: isLoading ? null : () => onPageChanged(page),
          style: TextButton.styleFrom(
            backgroundColor: isCurrentPage
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            foregroundColor: isCurrentPage
                ? Colors.white
                : Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isCurrentPage
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            padding: EdgeInsets.zero,
            minimumSize: Size(buttonSize, buttonSize),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: screenWidth < 360 ? 10 : 12),
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth < 360 ? 24.0 : 28.0; // Smaller than regular buttons
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 0.25 : 0.5), // Reduced padding
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Center(
          child: Text(
            '...',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: screenWidth < 360 ? 8 : 10),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
