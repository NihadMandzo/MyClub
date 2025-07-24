import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/providers/auth_provider.dart';
import 'package:provider/provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? baseUrl;
  String endpoint = "";
  late BuildContext context;
  AuthProvider? authProvider;

  BaseProvider(String endpoint) {
    this.endpoint = endpoint;
    baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "http://localhost:5206/api/");
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
    } else if (response.statusCode == 401) {
      throw new Exception("Unauthorized - Please log in again");
    } else {
      throw new Exception("API Error (${response.statusCode}): ${response.body}");
    }
  }

  Map<String, String> createHeaders() {
    var headers = {
      "Content-Type": "application/json",
    };
    
    if (authProvider?.token != null) {
      headers["Authorization"] = "Bearer ${authProvider!.token}";
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