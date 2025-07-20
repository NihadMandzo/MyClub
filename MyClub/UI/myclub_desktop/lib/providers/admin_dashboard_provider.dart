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

    print("Requesting membership data from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Membership response code: ${response.statusCode}");
      print("Membership response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['data'];
        return data.map((item) => DashboardMembershipPerMonthResponse.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load membership data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getMembershipPerMonth: $e");
      rethrow;
    }
  }

  Future<List<DashboardSalesByCategoryResponse>> getSalesPerCategory() async {
    var url = "${BaseProvider.baseUrl}$endpoint/SalesPerCategory";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting sales data from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Sales response code: ${response.statusCode}");
      print("Sales response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['data'];
        return data.map((item) => DashboardSalesByCategoryResponse.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load sales by category data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getSalesPerCategory: $e");
      rethrow;
    }
  }

  Future<List<DashboardRevenuePerMonthResponse>> getRevenuePerMonth() async {
    var url = "${BaseProvider.baseUrl}$endpoint/RevenuePerMonth";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting revenue data from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Revenue response code: ${response.statusCode}");
      print("Revenue response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['data'];
        return data.map((item) => DashboardRevenuePerMonthResponse.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load revenue data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getRevenuePerMonth: $e");
      rethrow;
    }
  }

  Future<DashboardCountResponse> getMembershipCount() async {
    var url = "${BaseProvider.baseUrl}$endpoint/MembershipCount";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting membership count from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Membership count response code: ${response.statusCode}");
      print("Membership count response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        Map<String, dynamic> data = jsonResponse['data'];
        return DashboardCountResponse.fromJson(data);
      } else {
        throw Exception("Failed to load membership count: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getMembershipCount: $e");
      rethrow;
    }
  }

  Future<DashboardMostSoldProductResponse> getMostSoldProduct() async {
    var url = "${BaseProvider.baseUrl}$endpoint/MostSoldProduct";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting most sold product from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Most sold product response code: ${response.statusCode}");
      print("Most sold product response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        Map<String, dynamic> data = jsonResponse['data'];
        return DashboardMostSoldProductResponse.fromJson(data);
      } else {
        throw Exception("Failed to load most sold product: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getMostSoldProduct: $e");
      rethrow;
    }
  }

  Future<DashboardCountResponse> getOrderCount() async {
    var url = "${BaseProvider.baseUrl}$endpoint/OrderCount";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting order count from: $uri");
    try {
      var response = await http.get(uri, headers: headers);
      print("Order count response code: ${response.statusCode}");
      print("Order count response body: ${response.body}");

      if (isValidResponse(response)) {
        var jsonResponse = jsonDecode(response.body);
        Map<String, dynamic> data = jsonResponse['data'];
        return DashboardCountResponse.fromJson(data);
      } else {
        throw Exception("Failed to load order count: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getOrderCount: $e");
      rethrow;
    }
  }

  @override
  bool isValidResponse(http.Response response) {
    print("Response status code: ${response.statusCode}");
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      print("Unauthorized: ${response.body}");
      throw Exception("Unauthorized - Please check if you're logged in with admin privileges");
    } else {
      print("Error response: ${response.body}");
      throw Exception("Server error (${response.statusCode}): ${response.body}");
    }
  }

  @override
  dynamic fromJson(data) {
    // Not used for this provider as we have specific response models
    throw UnimplementedError();
  }
}
