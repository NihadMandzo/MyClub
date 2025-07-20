import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/auth_response.dart';

class AuthProvider with ChangeNotifier {
  String? username;
  String? password;
  String? token;
  int? userId;
  String? roleName;
  int? roleId;
  AuthResponse? authResponse;
  String? errorMessage;
  bool isLoading = false;

  Future<bool> login(String username, String password) async {
    this.username = username;
    this.password = password;
    
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      var url = const String.fromEnvironment("baseUrl", 
          defaultValue: "http://localhost:5206/api/Users/") + "login";
      var uri = Uri.parse(url);

      print("Login URL: $uri");
      var response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "password": password
        }),
      );

      print("Login response code: ${response.statusCode}");
      print("Login response body: ${response.body}");
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        authResponse = AuthResponse.fromJson(jsonResponse);
        
        token = authResponse!.token;
        userId = authResponse!.userId;
        roleId = authResponse!.roleId;
        roleName = authResponse!.roleName;
        
        print("Login successful: Token received");
        isLoading = false;
        notifyListeners();
        return true;
      }
      
      errorMessage = "Invalid username or password (${response.statusCode})";
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = "Connection error: $e";
      isLoading = false;
      notifyListeners();
      print("Login error: $e");
      return false;
    }
  }

  void logout() {
    username = null;
    password = null;
    token = null;
    userId = null;
    roleId = null;
    roleName = null;
    authResponse = null;
    notifyListeners();
  }

  bool get isAuthenticated => token != null;
}