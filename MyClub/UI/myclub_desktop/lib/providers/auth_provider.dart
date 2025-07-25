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
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        authResponse = AuthResponse.fromJson(jsonResponse);
        
        // First check for admin role
        if (authResponse!.roleId != 1) {
          // Don't set any auth data if not an admin
          errorMessage = "Pristup odbijen: Samo administratori mogu koristiti ovu aplikaciju.";
          isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Only set authentication data if it's an admin user
        token = authResponse!.token;
        userId = authResponse!.userId;
        roleId = authResponse!.roleId;
        roleName = authResponse!.roleName;
        
        print("Login successful: Token received for admin user");
        isLoading = false;
        notifyListeners();
        return true;
      }
      
      errorMessage = "Neispravno korisničko ime ili lozinka";
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = "Greška povezivanja: $e";
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
  
  // Additional check to ensure only admins are authorized
  bool get isAuthorized => token != null && roleId == 1;
}