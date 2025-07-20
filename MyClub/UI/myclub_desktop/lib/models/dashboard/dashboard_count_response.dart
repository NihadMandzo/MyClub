class DashboardCountResponse {
  final int totalCount;
  final int thisMonth;
  final int lastMonth;
  final double percentageChange;

  DashboardCountResponse({
    required this.totalCount,
    required this.thisMonth,
    required this.lastMonth,
    required this.percentageChange,
  });

  factory DashboardCountResponse.fromJson(Map<String, dynamic> json) {
    return DashboardCountResponse(
      totalCount: json['totalCount'],
      thisMonth: json['thisMonth'],
      lastMonth: json['lastMonth'],
      percentageChange: json['percentageChange']?.toDouble() ?? 0.0,
    );
  }
}
