class DashboardMembershipPerMonthResponse {
  final String month;
  final int year;
  final String monthName;
  final int count;

  DashboardMembershipPerMonthResponse({
    required this.month,
    required this.year,
    required this.monthName,
    required this.count,
  });

  factory DashboardMembershipPerMonthResponse.fromJson(Map<String, dynamic> json) {
    return DashboardMembershipPerMonthResponse(
      month: json['month'],
      year: json['year'],
      monthName: json['monthName'],
      count: json['count'],
    );
  }
}
