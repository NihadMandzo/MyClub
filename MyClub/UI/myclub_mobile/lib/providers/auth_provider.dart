import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/responses/auth_response.dart';
import 'package:myclub_mobile/models/requests/user_upsert_request.dart';
import '../utility/auth_helper.dart';
import '../utility/api_config.dart';

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
      // Use ApiConfig to get the appropriate URL for the current platform
      var url = ApiConfig.loginUrl;
      var uri = Uri.parse(url);

      // Print configuration for debugging
      ApiConfig.printConfig();

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
        
        // First check for user role (roleId should be 2 for user based on your change)
        if (authResponse!.roleId != 2) {
          // Don't set any auth data if not a user
          errorMessage = "Pristup odbijen: Samo korisnici mogu koristiti ovu aplikaciju.";
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

  Future<void> logout() async {
    username = null;
    password = null;
    token = null;
    userId = null;
    roleId = null;
    roleName = null;
    authResponse = null;
    
    // Clear stored auth data
    await AuthHelper.clearAuthData();
    
    notifyListeners();
  }

  bool get isAuthenticated => token != null;
  
  // Additional check to ensure only admins are authorized (roleId = 2)
  bool get isAuthorized => token != null && roleId == 2;

  /// Register a new user
  Future<bool> register(UserUpsertRequest request) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      var url = '${ApiConfig.usersUrl}register'; // This will be the base users endpoint
      var uri = Uri.parse(url);

      // Print configuration for debugging
      ApiConfig.printConfig();
      print("Register URL: $uri");

      var response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode(request.toJson()),
      );

      print("Register response code: ${response.statusCode}");
      print("Register response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Try to parse error message from response
        try {
          var errorResponse = json.decode(response.body);
          if (errorResponse is Map && errorResponse.containsKey('message')) {
            errorMessage = errorResponse['message'];
          } else if (errorResponse is Map && errorResponse.containsKey('errors')) {
            errorMessage = errorResponse['errors'].toString();
          } else {
            errorMessage = "Greška prilikom registracije";
          }
        } catch (e) {
          errorMessage = "Greška prilikom registracije: ${response.body}";
        }
        
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = "Greška povezivanja: $e";
      isLoading = false;
      notifyListeners();
      print("Register error: $e");
      return false;
    }
  }
}