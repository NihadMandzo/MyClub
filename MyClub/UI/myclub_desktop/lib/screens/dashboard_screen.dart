import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_count_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_membership_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_most_sold_product_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_revenue_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_sales_by_category_response.dart';
import 'package:myclub_desktop/providers/admin_dashboard_provider.dart';
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
    setState(() {
      _isLoading = true;
    });

    try {
      // Load each data item separately to better identify issues
      try {
        _ordersCount = await _dashboardProvider.getOrderCount();
        print("Successfully loaded order count data");
      } catch (e) {
        print("Error loading order count: $e");
      }
      
      try {
        _membershipCount = await _dashboardProvider.getMembershipCount();
        print("Successfully loaded membership count data");
      } catch (e) {
        print("Error loading membership count: $e");
      }
      
      try {
        _mostSoldProduct = await _dashboardProvider.getMostSoldProduct();
        print("Successfully loaded most sold product data");
      } catch (e) {
        print("Error loading most sold product: $e");
      }
      
      try {
        _membershipPerMonth = await _dashboardProvider.getMembershipPerMonth();
        print("Successfully loaded membership per month data");
      } catch (e) {
        print("Error loading membership per month: $e");
      }
      
      try {
        _salesByCategory = await _dashboardProvider.getSalesPerCategory();
        print("Successfully loaded sales by category data");
      } catch (e) {
        print("Error loading sales by category: $e");
      }
      
      try {
        _revenuePerMonth = await _dashboardProvider.getRevenuePerMonth();
        print("Successfully loaded revenue per month data");
      } catch (e) {
        print("Error loading revenue per month: $e");
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("General error in _loadData: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: $e'),
          duration: Duration(seconds: 10),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
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
                    'Ukupan broj korisnika',
                    _membershipCount?.totalCount.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMostSoldProduct(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMembershipChart(),
                ),
                Expanded(
                  child: _buildSalesByCategoryChart(),
                ),
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

    final spots = _revenuePerMonth!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.totalAmount);
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
            'Zarada po mjesecima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} ${_revenuePerMonth!.isNotEmpty ? _revenuePerMonth![0].currency : ''}',
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
                        if (value.toInt() >= 0 && value.toInt() < _revenuePerMonth!.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _revenuePerMonth![value.toInt()].monthName.substring(0, 3),
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
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: (_revenuePerMonth!.length - 1).toDouble(),
                minY: 0,
                maxY: _revenuePerMonth!.map((e) => e.totalAmount).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
