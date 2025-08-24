import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:myclub_desktop/models/search_objects/base_search_object.dart';
import 'package:myclub_desktop/models/user_membership.dart';
import 'package:myclub_desktop/providers/user_membership_provider.dart';

class UserMembershipsScreen extends StatelessWidget {
  const UserMembershipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserMembershipProvider()..setContext(context),
      child: const _UserMembershipsContent(),
    );
  }
}

class _UserMembershipsContent extends StatefulWidget {
  const _UserMembershipsContent({Key? key}) : super(key: key);

  @override
  State<_UserMembershipsContent> createState() => _UserMembershipsContentState();
}

class _UserMembershipsContentState extends State<_UserMembershipsContent> {
  late UserMembershipProvider _provider;
  List<UserMembership> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1; // 1-based for UI
  int _totalPages = 0;
  final int _pageSize = 10;
  String? _searchText;
  BaseSearchObject _searchObject = BaseSearchObject(page: 0, pageSize: 10); // 0-based for API
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _updatingIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<UserMembershipProvider>();
    _provider.setContext(context);
    if (_isLoading && _items.isEmpty && _errorMessage == null) {
      _initData();
    }
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _provider.get(searchObject: _searchObject);
      setState(() {
        _items = result.data;
        _totalPages = (result.totalCount / _pageSize).ceil();
        _isLoading = false;
      });
      if (_totalPages > 0 && _currentPage > _totalPages) {
        setState(() {
          _currentPage = _totalPages;
          _searchObject.page = _currentPage - 1; // 0-based
        });
        await _initData();
        return;
      }
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
  _searchObject.page = page - 1; // 0-based for API
      });
      _initData();
    }
  }

  void _onSearch() {
    final searchText = _searchController.text.trim();
    setState(() {
      _searchText = searchText;
      _currentPage = 1;
  _searchObject.page = 0; // reset to first (0-based)
      _searchObject.fts = searchText.isNotEmpty ? searchText : null;
    });
    _initData();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = null;
      _currentPage = 1;
  _searchObject.page = 0; // reset to first (0-based)
      _searchObject.fts = null;
    });
    _initData();
  }

  Future<void> _markAsShipped(UserMembership m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Označi kao poslano'),
        content: Text('Označiti članarinu ${m.membershipName} (${m.year}) za korisnika ${m.userFullName} kao poslanu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ne')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Da')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _updatingIds.add(m.id);
    });

    try {
      await _provider.markAsShipped(m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Članarina označena kao poslano.')));
      await _initData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Greška pri označavanju: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _updatingIds.remove(m.id);
        });
      }
    }
  }

  Color _statusColor(UserMembership m) {
    if (m.isShipped) return Colors.green;
    if (m.physicalCardRequested) return Colors.orange;
    return Colors.grey;
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
              'Korisnička članstva',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraga po imenu korisnika ili članarini',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pretraži'),
                ),
                const SizedBox(width: 8),
                if (_searchText != null && _searchText!.isNotEmpty)
                  TextButton(onPressed: _clearSearch, child: const Text('Očisti')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Greška: $_errorMessage', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _initData, child: const Text('Ponovo pokušaj')),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(child: Text('Nema članarina', style: TextStyle(fontSize: 16)))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final m = _items[index];
                                final statusColor = _statusColor(m);
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${m.membershipName} • ${m.year}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                                              child: Text(
                                                m.isShipped
                                                    ? 'Poslano'
                                                    : (m.physicalCardRequested ? 'Za slanje' : 'Digitalno'),
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(m.userFullName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Text('Datum učlanjenja: ${DateFormat('dd.MM.yyyy').format(m.joinDate)}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        const SizedBox(height: 4),
                                        Text('Plaćanje: ${m.paymentAmountText} • ${m.isPaid ? 'Plaćeno' : 'Neplaćeno'}',
                                            style: TextStyle(fontSize: 13, color: m.isPaid ? Colors.green : Colors.red)),
                                        const SizedBox(height: 8),
                                        if (m.physicalCardRequested) ...[
                                          Text(
                                            'Primatelj: ${(m.recipientFullName ?? m.userFullName)}',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Email: ${m.recipientEmail ?? '-'}',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Adresa: ${m.shippingAddress ?? '-'}'
                                            '${m.shippingCity != null && m.shippingCity!.name.isNotEmpty ? ', ${m.shippingCity!.name}' : ''}',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Datum slanja: ${m.shippedDate != null ? DateFormat('dd.MM.yyyy').format(m.shippedDate!) : '-'}', style: const TextStyle(fontSize: 13)),
                                        ],
                                        const Spacer(),
                                        if (m.physicalCardRequested && !m.isShipped)
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: _updatingIds.contains(m.id) ? null : () => _markAsShipped(m),
                                              icon: _updatingIds.contains(m.id)
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                    )
                                                  : const Icon(Icons.local_shipping_outlined),
                                              label: const Text('Označi kao poslano'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            if (_items.isNotEmpty && _totalPages > 1)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        disabledBackgroundColor: Colors.blue.shade100,
                      ),
                      child: const Text('Prethodni'),
                    ),
                    const SizedBox(width: 16),
                    for (int i = 1; i <= _totalPages; i++)
                      if (i == 1 || i == _totalPages || (i >= _currentPage - 1 && i <= _currentPage + 1))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: i != _currentPage ? () => _onPageChanged(i) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: i == _currentPage ? Colors.blue.shade700 : Colors.blue.shade200,
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
                          child: Text('...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
