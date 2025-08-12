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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page size selector (left side)
          if (showPageSizeSelector && onPageSizeChanged != null) ...[
            Text(
              'Po stranici:',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 12),
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: currentPageSize,
                  items: pageSizeOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 12),
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
            const SizedBox(width: 16),
          ],
          
          // Navigation controls (center)
          if (totalPages > 1) ...[
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
                minimumSize: const Size(32, 32),
              ),
            ),
            
            // Page indicators (only show if showPageNumbers is true)
            if (showPageNumbers) ...[
              const SizedBox(width: 8),
              // Center the page buttons with proper constraints
              ...(_buildPageButtons(context)),
              const SizedBox(width: 8),
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
                minimumSize: const Size(32, 32),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons(BuildContext context) {
    List<Widget> buttons = [];
    
    if (totalPages <= 0) return buttons;
    
    // Show fewer pages in single row to avoid overcrowding
    int maxPagesToShow = 3;
    int halfRange = maxPagesToShow ~/ 2;
    
    int startPage = 0;
    int endPage = totalPages;
    
    if (totalPages > maxPagesToShow) {
      startPage = (currentPage - halfRange).clamp(0, totalPages - maxPagesToShow);
      endPage = startPage + maxPagesToShow;
    }
    
    // Show range of pages around current page
    for (int i = startPage; i < endPage && i < totalPages; i++) {
      buttons.add(_buildPageButton(context, i));
    }
    
    return buttons;
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final isCurrentPage = page == currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: SizedBox(
        width: 32,
        height: 32,
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
            minimumSize: const Size(32, 32),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 12),
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
