import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isLoading;
  final bool showPageNumbers;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.isLoading = false,
    this.showPageNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: showPageNumbers 
            ? MainAxisAlignment.center 
            : MainAxisAlignment.spaceBetween,
        children: [
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
            ),
          ),
          
          // Page indicators (only show if showPageNumbers is true)
          if (showPageNumbers) ...[
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageButtons(context),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons(BuildContext context) {
    List<Widget> buttons = [];
    
    if (totalPages <= 0) return buttons;
    
    // For simplicity, show up to 5 pages around the current page
    int maxPagesToShow = 5;
    int halfRange = maxPagesToShow ~/ 2;
    
    int startPage = 0;
    int endPage = totalPages;
    
    if (totalPages > maxPagesToShow) {
      startPage = (currentPage - halfRange).clamp(0, totalPages - maxPagesToShow);
      endPage = startPage + maxPagesToShow;
    }
    
    // Always show first page if not in range
    if (startPage > 0) {
      buttons.add(_buildPageButton(context, 0));
      if (startPage > 1) {
        buttons.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '...',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.grey.shade600,
            ),
          ),
        ));
      }
    }
    
    // Show range of pages
    for (int i = startPage; i < endPage && i < totalPages; i++) {
      buttons.add(_buildPageButton(context, i));
    }
    
    // Always show last page if not in range
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        buttons.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '...',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.grey.shade600,
            ),
          ),
        ));
      }
      buttons.add(_buildPageButton(context, totalPages - 1));
    }
    
    return buttons;
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final isCurrentPage = page == currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 40,
        height: 40,
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
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isCurrentPage
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
