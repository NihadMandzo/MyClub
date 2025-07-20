class DashboardSalesByCategoryResponse {
  final int categoryId;
  final String categoryName;
  final int totalSold;
  final double totalRevenue;
  final double percentage;

  DashboardSalesByCategoryResponse({
    required this.categoryId,
    required this.categoryName,
    required this.totalSold,
    required this.totalRevenue,
    required this.percentage,
  });

  factory DashboardSalesByCategoryResponse.fromJson(Map<String, dynamic> json) {
    return DashboardSalesByCategoryResponse(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      totalSold: json['totalSold'],
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
    );
  }
}
