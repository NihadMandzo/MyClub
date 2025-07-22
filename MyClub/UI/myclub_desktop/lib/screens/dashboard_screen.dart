import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_count_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_membership_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_most_sold_product_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_revenue_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_sales_by_category_response.dart';
import 'package:myclub_desktop/providers/admin_dashboard_provider.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        var provider = AdminDashboardProvider();
        provider.setContext(context);
        return provider;
      },
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({Key? key}) : super(key: key);

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late AdminDashboardProvider _dashboardProvider;
  bool _isLoading = true;

  // Dashboard data
  DashboardCountResponse? _ordersCount;
  DashboardCountResponse? _membershipCount;
  DashboardMostSoldProductResponse? _mostSoldProduct;
  List<DashboardMembershipPerMonthResponse>? _membershipPerMonth;
  List<DashboardSalesByCategoryResponse>? _salesByCategory;
  List<DashboardRevenuePerMonthResponse>? _revenuePerMonth;

  @override
  void initState() {
    super.initState();
    _dashboardProvider = context.read<AdminDashboardProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _dashboardProvider.getOrderCount(),
        _dashboardProvider.getMembershipCount(),
        _dashboardProvider.getMostSoldProduct(),
        _dashboardProvider.getMembershipPerMonth(),
        _dashboardProvider.getSalesPerCategory(),
        _dashboardProvider.getRevenuePerMonth(),
      ]);

      if (!mounted) return;
      setState(() {
        _ordersCount = results[0] as DashboardCountResponse;
        _membershipCount = results[1] as DashboardCountResponse;
        _mostSoldProduct = results[2] as DashboardMostSoldProductResponse;
        _membershipPerMonth = results[3] as List<DashboardMembershipPerMonthResponse>;
        _salesByCategory = results[4] as List<DashboardSalesByCategoryResponse>;
        _revenuePerMonth = results[5] as List<DashboardRevenuePerMonthResponse>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("General error in _loadData: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationUtility.showError(
        context,
        message: 'Greška pri učitavanju podataka: $e',
        duration: const Duration(seconds: 10),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analiza',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCountCard(
                    'Ukupan broj narudžbi',
                    _ordersCount?.totalCount.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCountCard(
                    'Ukupan broj članova',
                    _membershipCount?.totalCount.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMostSoldProduct()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMembershipChart()),
                Expanded(child: _buildSalesByCategoryChart()),
              ],
            ),
            const SizedBox(height: 24),
            _buildRevenueChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostSoldProduct() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Najprodavaniji proizvod',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _mostSoldProduct?.productName ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipChart() {
    if (_membershipPerMonth == null || _membershipPerMonth!.isEmpty) {
      return const Center(child: Text('No membership data available'));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Članstvo po mjesecima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _membershipPerMonth!.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_membershipPerMonth![groupIndex].monthName}: ${rod.toY.round()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _membershipPerMonth!.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _membershipPerMonth![value.toInt()].monthName.substring(0, 3),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _membershipPerMonth!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.count.toDouble(),
                        color: Colors.blue,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesByCategoryChart() {
    if (_salesByCategory == null || _salesByCategory!.isEmpty) {
      return const Center(child: Text('No sales data available'));
    }

    final pieChartSections = _salesByCategory!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      // Generate a color based on index to ensure different colors
      final color = Colors.primaries[index % Colors.primaries.length];
      
      return PieChartSectionData(
        value: data.percentage.toDouble(),
        title: '${data.percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prodaja proizvoda po kategorijama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: pieChartSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      pieTouchData: PieTouchData(),
                    ),
                  ),
                ),
                if (_salesByCategory!.length > 0)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _salesByCategory!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final color = Colors.primaries[index % Colors.primaries.length];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data.categoryName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenuePerMonth == null || _revenuePerMonth!.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    // Create a map with month indices for proper sorting (1-based for months)
    final Map<String, int> monthIndices = {
      'Januar': 1, 'Februar': 2, 'Mart': 3, 'April': 4,
      'Maj': 5, 'Juni': 6, 'Juli': 7, 'August': 8,
      'Septembar': 9, 'Oktobar': 10, 'Novembar': 11, 'Decembar': 12
    };
    
    // Process data - use Map to ensure each month appears only once
    Map<String, double> processedData = {};
    
    // Group revenue by month name
    for (var data in _revenuePerMonth!) {
      // If we've already seen this month, add to its revenue
      if (processedData.containsKey(data.monthName)) {
        processedData[data.monthName] = processedData[data.monthName]! + data.totalAmount;
      } else {
        processedData[data.monthName] = data.totalAmount;
      }
    }
    
    // Convert to a list for display
    List<MapEntry<String, double>> monthRevenueList = processedData.entries.toList();
    
    // Sort by calendar month order
    monthRevenueList.sort((a, b) {
      int aIndex = monthIndices[a.key] ?? 999;
      int bIndex = monthIndices[b.key] ?? 999;
      return aIndex.compareTo(bIndex);
    });
    
    // Get currency symbol
    final String currency = _revenuePerMonth!.isNotEmpty ? _revenuePerMonth![0].currency : '';

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Zarada po mjesecima',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($currency)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: monthRevenueList.isEmpty 
                    ? 100
                    : monthRevenueList.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${monthRevenueList[group.x.toInt()].key}: ${rod.toY.round()} $currency',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Color(0xff68737d),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthRevenueList.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthRevenueList[value.toInt()].key.substring(0, 3),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                barGroups: monthRevenueList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value,
                        color: Colors.blue,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
