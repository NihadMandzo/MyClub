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
      
      // Only trigger global logout if not during PayPal confirmation
      // PayPal confirmations might fail due to expired tokens during long payment processes
      String requestUrl = response.request?.url.toString() ?? '';
      if (!requestUrl.contains('/confirm')) {
        _handleUnauthorized();
      }

      throw Exception("Neautorizovan - pokusajte se prijaviti ponovo");
    } else {
      print("Processing error response with status ${response.statusCode}");
      // Try to extract a user-friendly error message from JSON response
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          // Add status code to error map if not present
          if (!decoded.containsKey('status') && response.statusCode != 0) {
            decoded['status'] = response.statusCode;
          }
          
          final msg = _extractMessageFromErrorMap(decoded);
          if (msg != null && msg.trim().isNotEmpty) {
            throw Exception(msg.trim());
          }
        } else if (decoded is List) {
          // Sometimes APIs return a list of error strings
          if (decoded.isNotEmpty) {
            throw Exception(decoded.first.toString());
          }
        }
      } catch (jsonError) {
        print("Error parsing JSON response: $jsonError");
        // JSON parsing failed, continue with default handling below
      }

      // Handle specific legacy texts if present (fallback)
      if (response.statusCode == 400) {
        if (response.body.contains("Cannot delete this color") ||
            response.body.contains("cannot delete this color")) {
          throw Exception("Cannot delete this color as it's currently used by products");
        }
      }

      // Default error message if we couldn't parse a specific one
      throw Exception("Došlo je do greške (${response.statusCode}). Pokušajte ponovo.");
    }
  }

  /// Extracts a user-friendly message from common error response shapes.
  /// Supports:
  /// - ASP.NET Core ProblemDetails with `errors` dictionary
  /// - RFC9110 validation errors format with status and errors
  /// - Custom `{ errors: { key: [messages] } }` shapes
  String? _extractMessageFromErrorMap(Map<String, dynamic> map) {
    // RFC9110 validation errors format
    if (map['status'] is int && map['errors'] is Map) {
      final errorsMap = Map<String, dynamic>.from(map['errors'] as Map);
      final List<String> messages = [];

      errorsMap.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else if (value is String) {
          messages.add(value);
        }
      });

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    // Handle simple errors format with userError key
    if (map['errors'] is Map) {
      final errorsMap = Map<String, dynamic>.from(map['errors'] as Map);
      
      // Prioritize userError key as requested
      if (errorsMap['userError'] != null) {
        final val = errorsMap['userError'];
        if (val is List && val.isNotEmpty) {
          return "userError: ${val.join('\n')}";
        }
        if (val is String) {
          return "userError: $val";
        }
      }

      // Handle other error keys
      final List<String> messages = [];
      errorsMap.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else if (value is String) {
          messages.add(value);
        }
      });

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    // If there is a top-level message field
    if (map['message'] is String && (map['message'] as String).trim().isNotEmpty) {
      return map['message'] as String;
    }

    // ProblemDetails style
    final title = map['title'];
    final detail = map['detail'];

    // If there is a single `errors` string/list
    final errorsField = map['errors'];
    if (errorsField is String && errorsField.trim().isNotEmpty) {
      return errorsField;
    }
    if (errorsField is List && errorsField.isNotEmpty) {
      return errorsField.first.toString();
    }

    // Fall back to detail/title if present
    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }
    if (title is String && title.trim().isNotEmpty) {
      return title;
    }

    return null;
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