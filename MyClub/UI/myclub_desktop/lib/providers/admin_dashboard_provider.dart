import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/dashboard/dashboard_count_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_membership_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_most_sold_product_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_revenue_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_sales_by_category_response.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class AdminDashboardProvider extends BaseProvider {
  AdminDashboardProvider() : super('AdminDashboard');

  Map<String, String> createHeaders() {
    var headers = {
      "Content-Type": "application/json",
    };
    
    if (authProvider != null && authProvider!.token != null) {
      headers["Authorization"] = "Bearer ${authProvider!.token}";
    }
    
    return headers;
  }

  Future<List<DashboardMembershipPerMonthResponse>> getMembershipPerMonth() async {
    var url = "${BaseProvider.baseUrl}$endpoint/MembershipPerMonth";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DashboardMembershipPerMonthResponse.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load membership data");
    }
  }

  Future<List<DashboardSalesByCategoryResponse>> getSalesPerCategory() async {
    var url = "${BaseProvider.baseUrl}$endpoint/SalesPerCategory";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DashboardSalesByCategoryResponse.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load sales by category data");
    }
  }

  Future<List<DashboardRevenuePerMonthResponse>> getRevenuePerMonth() async {
    var url = "${BaseProvider.baseUrl}$endpoint/RevenuePerMonth";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DashboardRevenuePerMonthResponse.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load revenue data");
    }
  }

  Future<DashboardCountResponse> getMembershipCount() async {
    var url = "${BaseProvider.baseUrl}$endpoint/MembershipCount";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return DashboardCountResponse.fromJson(data);
    } else {
      throw Exception("Failed to load membership count");
    }
  }

  Future<DashboardMostSoldProductResponse> getMostSoldProduct() async {
    var url = "${BaseProvider.baseUrl}$endpoint/MostSoldProduct";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return DashboardMostSoldProductResponse.fromJson(data);
    } else {
      throw Exception("Failed to load most sold product");
    }
  }

  Future<DashboardCountResponse> getOrderCount() async {
    var url = "${BaseProvider.baseUrl}$endpoint/OrderCount";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return DashboardCountResponse.fromJson(data);
    } else {
      throw Exception("Failed to load order count");
    }
  }

  @override
  dynamic fromJson(data) {
    // Not used for this provider as we have specific response models
    throw UnimplementedError();
  }
}
