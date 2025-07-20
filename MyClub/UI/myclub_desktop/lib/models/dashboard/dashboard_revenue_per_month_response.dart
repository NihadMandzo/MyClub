class DashboardRevenuePerMonthResponse {
  final String month;
  final int year;
  final String monthName;
  final double totalAmount;
  final String currency;

  DashboardRevenuePerMonthResponse({
    required this.month,
    required this.year,
    required this.monthName,
    required this.totalAmount,
    required this.currency,
  });

  factory DashboardRevenuePerMonthResponse.fromJson(Map<String, dynamic> json) {
    return DashboardRevenuePerMonthResponse(
      month: json['month'],
      year: json['year'],
      monthName: json['monthName'],
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      currency: json['currency'],
    );
  }
}
