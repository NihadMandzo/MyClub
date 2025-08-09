// Model and helpers for Dashboard PDF generation requests

enum DashboardReportType {
  top10MostSoldProducts, // 1
  top10LeastSoldProducts, // 2
  membershipsPerMonth, // 3
  revenuePerMonth, // 4
}

extension DashboardReportTypeX on DashboardReportType {
  int get value {
    switch (this) {
      case DashboardReportType.top10MostSoldProducts:
        return 1;
      case DashboardReportType.top10LeastSoldProducts:
        return 2;
      case DashboardReportType.membershipsPerMonth:
        return 3;
      case DashboardReportType.revenuePerMonth:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case DashboardReportType.top10MostSoldProducts:
        return 'Top 10 najprodavanijih';
      case DashboardReportType.top10LeastSoldProducts:
        return 'Top 10 najmanje prodavanih';
      case DashboardReportType.membershipsPerMonth:
        return 'Članstva po mjesecima';
      case DashboardReportType.revenuePerMonth:
        return 'Zarada po mjesecima';
    }
  }
}

class DashboardReportRequest {
  final DashboardReportType type;
  DashboardReportRequest(this.type);

  Map<String, dynamic> toJson() => {
        'type': type.value,
      };
}
