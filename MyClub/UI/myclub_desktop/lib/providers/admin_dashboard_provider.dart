import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/dashboard/dashboard_count_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_membership_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_most_sold_product_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_revenue_per_month_response.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_sales_by_category_response.dart';
import 'package:myclub_desktop/providers/base_provider.dart';
import 'package:myclub_desktop/models/dashboard/dashboard_report_request.dart';
import 'dart:typed_data';

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

  // Generate dashboard PDF report
  Future<({Uint8List bytes, String filename})> generateDashboardPdf(DashboardReportType type) async {
    final url = "${BaseProvider.baseUrl}$endpoint/dashboard/pdf";
    final uri = Uri.parse(url);

    final headers = {
      ...createHeaders(),
      'Accept': 'application/pdf',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode(DashboardReportRequest(type).toJson());
    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final filename = _parseFilename(response.headers['content-disposition']) ?? _defaultFilename(type);
      return (bytes: response.bodyBytes, filename: filename);
    }

    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['message'] is String) {
        throw Exception(err['message']);
      }
    } catch (_) {}
    throw Exception('Neuspješno generisanje PDF-a (status ${response.statusCode}).');
  }

  String _defaultFilename(DashboardReportType type) {
    switch (type) {
      case DashboardReportType.top10MostSoldProducts:
        return 'Top10_Najprodavaniji_Proizvodi.pdf';
      case DashboardReportType.top10LeastSoldProducts:
        return 'Top10_Najmanje_Prodavani_Proizvodi.pdf';
      case DashboardReportType.membershipsPerMonth:
        return 'Broj_Clanova_Po_Mjesecima.pdf';
      case DashboardReportType.revenuePerMonth:
        return 'Mjesecna_Zarada.pdf';
    }
  }

  String? _parseFilename(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    final parts = contentDisposition.split(';');

    // 1) Prefer RFC 5987 filename*
    for (final raw in parts) {
      final part = raw.trim();
      if (part.toLowerCase().startsWith('filename*=')) {
        var value = part.substring(part.indexOf('=') + 1).trim();
        if (value.startsWith('"') && value.endsWith('"') && value.length > 1) {
          value = value.substring(1, value.length - 1);
        }

        // charset'lang'percent-encoded-filename (or UTF-8''name)
        final first = value.indexOf("'");
        final second = value.indexOf("'", first + 1);
        if (first != -1 && second != -1 && second + 1 < value.length) {
          final encoded = value.substring(second + 1);
          final decoded = Uri.decodeComponent(encoded);
          final sanitized = _ensurePdfExtension(_sanitizeFilename(decoded));
          return sanitized;
        }

        const marker1 = "UTF-8''";
        const marker2 = "utf-8''";
        if (value.startsWith(marker1) || value.startsWith(marker2)) {
          final decoded = Uri.decodeComponent(value.substring(marker1.length));
          final sanitized = _ensurePdfExtension(_sanitizeFilename(decoded));
          return sanitized;
        }
      }
    }

    // 2) Fallback to simple filename=
    for (final raw in parts) {
      final part = raw.trim();
      if (part.toLowerCase().startsWith('filename=')) {
        var value = part.substring(part.indexOf('=') + 1).trim();
        if (value.startsWith('"') && value.endsWith('"') && value.length > 1) {
          value = value.substring(1, value.length - 1);
        }
        final sanitized = _ensurePdfExtension(_sanitizeFilename(value));
        return sanitized;
      }
    }

    return null;
  }

  String _sanitizeFilename(String name) {
    name = name.replaceAll('\\', '/').split('/').last;
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (name.isEmpty) return 'report.pdf';
    return name;
  }

  String _ensurePdfExtension(String name) {
    return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
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
