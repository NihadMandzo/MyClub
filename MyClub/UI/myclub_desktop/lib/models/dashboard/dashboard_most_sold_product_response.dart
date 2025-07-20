class DashboardMostSoldProductResponse {
  final int productId;
  final String productName;
  final String category;
  final int totalSold;
  final double totalRevenue;
  final String? imageUrl;

  DashboardMostSoldProductResponse({
    required this.productId,
    required this.productName,
    required this.category,
    required this.totalSold,
    required this.totalRevenue,
    this.imageUrl,
  });

  factory DashboardMostSoldProductResponse.fromJson(Map<String, dynamic> json) {
    return DashboardMostSoldProductResponse(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? 'Unknown',
      category: json['category'] ?? 'Unknown',
      totalSold: json['totalSold'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
    );
  }
}
