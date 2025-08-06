import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/models/order.dart';
import 'package:myclub_desktop/models/search_objects/base_search_object.dart';
import 'package:myclub_desktop/providers/order_provider.dart';
import 'package:myclub_desktop/utilities/order_details_dialog.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderProvider(),
      child: const _OrdersContent(),
    );
  }
}

class _OrdersContent extends StatefulWidget {
  const _OrdersContent({Key? key}) : super(key: key);

  @override
  State<_OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<_OrdersContent> {
  late OrderProvider _orderProvider;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  int _pageSize = 10;
  String? _searchText;

  BaseSearchObject _searchObject = BaseSearchObject(
    page: 1,
    pageSize: 10,
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _initData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderProvider = context.watch<OrderProvider>();
    _orderProvider.setContext(context);
  }

   void _initializeProvider() {
    _orderProvider = context.read<OrderProvider>();
    _orderProvider.setContext(context);
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _orderProvider.get(
        searchObject: _searchObject,
      );
      setState(() {
        _orders = result.data;
        _totalPages = (result.totalCount / _pageSize).ceil();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
        _searchObject.page = page;
      });
      _initData();
    }
  }

  void _onSearch() {
    final searchText = _searchController.text.trim();
    setState(() {
      _searchText = searchText;
      _currentPage = 1;
      _searchObject.page = 1;
      _searchObject.fts = searchText.isNotEmpty ? searchText : null;
    });
    _initData();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = null;
      _currentPage = 1;
      _searchObject.page = 1;
      _searchObject.fts = null;
    });
    _initData();
  }

  void _showOrderDetails(Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: _orderProvider,
        child: OrderDetailsDialog(order: order),
      ),
    );
    
    // If the status was updated, refresh the orders list
    if (result == true) {
      _initData();
    }
  }

  String _getStatusText(String orderState) {
    return orderState; // Return the status directly as it's already a display name
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search bar row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraga po broju narudžbe ili imenu kupca',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  child: const Text('Pretraži'),
                ),
                const SizedBox(width: 8),
                if (_searchText != null && _searchText!.isNotEmpty)
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Očisti'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _initData,
                                child: const Text('Ponovo pokušaj'),
                              ),
                            ],
                          ),
                        )
                      : _orders.isEmpty
                          ? const Center(
                              child: Text(
                                'Narudžbe nisu pronađene',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  
                                  // Define status color
                                  Color statusColor;
                                  
                                  // Assign color based on order state
                                  if (order.orderState == 'Procesiranje') {
                                    statusColor = Colors.blue;
                                  } else if (order.orderState == 'Potvrđeno') {
                                    statusColor = Colors.green;
                                  } else if (order.orderState == 'Otkazano') {
                                    statusColor = Colors.red;
                                  }  else if (order.orderState == 'Iniciranje') {
                                    statusColor = Colors.orange;
                                  } else if (order.orderState == 'Dostava') {
                                    statusColor = Colors.purple;
                                  } else if (order.orderState == 'Završeno') {
                                    statusColor = Colors.green;
                                  } else {
                                    statusColor = Colors.grey;
                                  }
                                  
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _showOrderDetails(order),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Order number and status
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'Narudžba #${order.orderNumber ?? order.id.toString()}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                                                                        _getStatusText(order.orderState),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // Customer name
                                            Text(
                                              order.userFullName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Order date
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(order.orderDate),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            
                                            const Spacer(),
                                            
                                            // Item count - fixed the OrderItem conflict by safely accessing the length
                                            Text(
                                              '${order.orderItems.length} stavka(e)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            
                                            // Total
                                            Text(
                                              '\$${order.totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
            
            // Pagination
            if (_totalPages > 0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    ElevatedButton(
                      onPressed: _currentPage > 1
                          ? () => _onPageChanged(_currentPage - 1)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        disabledBackgroundColor: Colors.blue.shade100,
                      ),
                      child: const Text('Prethodni'),
                    ),
                    const SizedBox(width: 16),

                    // Page numbers
                    for (int i = 1; i <= _totalPages; i++)
                      if (i == 1 ||
                          i == _totalPages ||
                          (i >= _currentPage - 1 && i <= _currentPage + 1))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: i != _currentPage
                                ? () => _onPageChanged(i)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: i == _currentPage
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade200,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(
                                  color: i == _currentPage ? Colors.blue.shade900 : Colors.transparent,
                                  width: i == _currentPage ? 2 : 0,
                                ),
                              ),
                              minimumSize: const Size(32, 32),
                            ),
                            child: Text('$i'),
                          ),
                        )
                      else if (i == _currentPage - 2 || i == _currentPage + 2)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),

                    const SizedBox(width: 16),

                    // Next button
                    ElevatedButton(
                      onPressed: _currentPage < _totalPages
                          ? () => _onPageChanged(_currentPage + 1)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        disabledBackgroundColor: Colors.blue.shade100,
                      ),
                      child: const Text('Sljedeći'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
