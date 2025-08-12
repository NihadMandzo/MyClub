import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:myclub_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../utility/api_config.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? baseUrl;
  static AuthProvider? _globalAuthProvider;
  static Function()? _globalUnauthorizedHandler;
  String endpoint = "";
  late BuildContext context;
  AuthProvider? authProvider;

  BaseProvider(String endpoint) {
    this.endpoint = endpoint;
    // Use ApiConfig to get platform-appropriate base URL
    baseUrl = ApiConfig.baseUrl;
  }

  /// Set global auth provider for use across all providers
  static void setGlobalAuthProvider(AuthProvider authProvider) {
    _globalAuthProvider = authProvider;
  }

  /// Get global auth provider
  static AuthProvider? getGlobalAuthProvider() {
    return _globalAuthProvider;
  }
  
  /// Set global unauthorized handler
  static void setGlobalUnauthorizedHandler(Function() handler) {
    _globalUnauthorizedHandler = handler;
  }
  
  /// Handle unauthorized access globally
  static void _handleUnauthorized() {
    if (_globalUnauthorizedHandler != null) {
      _globalUnauthorizedHandler!();
    }
  }
  
  void setContext(BuildContext context) {
    this.context = context;
    authProvider = Provider.of<AuthProvider>(this.context, listen: false);
  }


  
  Future<PagedResult<T>> get({dynamic searchObject}) async {
    var url = "$baseUrl$endpoint";

    if (searchObject != null) {
      // Convert search object to Map if it has a toJson method
      var filter = searchObject is Map ? searchObject : searchObject.toJson();
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    print("API GET Request URL: $url");
    print("API GET Request Headers: ${createHeaders()}");
    
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      
      return PagedResult<T>.fromJson(
        data,
        (item) => fromJson(item),
      );
    } else {
      throw Exception("Greška tokom dohvatanja podataka");
    }
  }
  
  Future<T> getById(int id) async {
    var url = "$baseUrl$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom dohvatanja podataka sa id: $id");
    }
  }

  Future<T> insert(dynamic request) async {
    var url = "$baseUrl$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom kreiranja stavke");
    }
  }

  Future<T> update(int id, [dynamic request]) async {
    var url = "$baseUrl$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom editovanja stavke");
    }
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }

  bool isValidResponse(http.Response response) {
    print("API Response Status Code: ${response.statusCode}");
    print("API Response Body: ${response.body}");
    
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Handle unauthorized/forbidden access
      print("Unauthorized access detected (${response.statusCode}). Triggering logout...");
      _handleUnauthorized();
      throw Exception("Unauthorized - Please log in again");
    } else {
      print("Processing error response with status ${response.statusCode}");

      // Handle specific cases first
      if (response.statusCode == 400) {
        // Direct hardcoded fix for the specific error we're seeing
        if (response.body.contains("Cannot delete this color") || 
            response.body.contains("cannot delete this color")) {
          throw Exception("Cannot delete this color as it's currently used by products");
        }
      }
      
      // Try to extract user-friendly error message from JSON response
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData.containsKey('errors')) {
          // Handle userError field if it exists
          if (errorData['errors'] is Map && errorData['errors'].containsKey('userError')) {
            final userErrors = errorData['errors']['userError'];
            if (userErrors is List && userErrors.isNotEmpty) {
              // Get the error message directly, no string manipulation needed
              var errorMsg = userErrors[0];
              
              // Special case for error we know contains an apostrophe
              if (errorMsg.toString().contains("it\\u0027s")) {
                throw Exception("Cannot delete this item as it's currently used by products");
              } else {
                throw Exception(errorMsg);
              }
            }
          }
          // Try other possible error formats
          else if (errorData['errors'] is List && (errorData['errors'] as List).isNotEmpty) {
            throw Exception((errorData['errors'] as List).first.toString());
          }
          else if (errorData['errors'] is String) {
            throw Exception(errorData['errors'].toString());
          }
        }
      } catch (jsonError) {
        print("Error parsing JSON response: $jsonError");
        // JSON parsing failed, continue with default error
      }

      // Default error message if we couldn't parse a specific one
      throw Exception("API Error (${response.statusCode}): ${response.body}");
    }
  }

  Map<String, String> createHeaders() {
    var headers = {
      "Content-Type": "application/json",
    };
    
    // Try to get token from local authProvider first, then global
    AuthProvider? auth = authProvider ?? _globalAuthProvider;
    
    if (auth?.token != null) {
      headers["Authorization"] = "Bearer ${auth!.token}";
      print("Including Authorization header with token: ${auth.token?.substring(0, 20)}...");
    } else {
      print("Warning: No authorization token available for API request");
    }

    return headers;
  }

  String getQueryString(Map params,
      {String prefix = '&', bool inRecursion = false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query +=
              getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }

  Future<void> delete(int id) async {
    var url = "$baseUrl$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (!isValidResponse(response)) {
      throw Exception("Greška tokom brisanja stavke sa id: $id");
    }
  }
}