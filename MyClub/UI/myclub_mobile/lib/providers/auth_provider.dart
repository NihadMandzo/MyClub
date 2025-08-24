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
        
        // Check for user role (roleId should be 2 for regular users, 1 for admin)
        if (authResponse!.roleId != 2 && authResponse!.roleId != 1) {
          // Don't set any auth data if not a user or admin
          errorMessage = "Pristup odbijen: Samo korisnici i administratori mogu koristiti ovu aplikaciju.";
          isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Set authentication data for both users and admins
        token = authResponse!.token;
        userId = authResponse!.userId;
        roleId = authResponse!.roleId;
        roleName = authResponse!.roleName;
        
        // Save auth data to SharedPreferences
        await AuthHelper.saveAuthData(
          token: token!,
          userId: userId!,
          roleId: roleId!,
          roleName: roleName!,
          username: username,
        );
        
        print("Login successful: Token received and saved for ${isAdmin ? 'admin' : 'user'}");
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
  
  // Check if user is admin (roleId = 1)
  bool get isAdmin => token != null && roleId == 1;
  
  // Check if user is regular user (roleId = 2)
  bool get isUser => token != null && roleId == 2;
  
  // Additional check to ensure users and admins are authorized
  bool get isAuthorized => token != null && (roleId == 1 || roleId == 2);

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
        // Try to parse error message from response (ProblemDetails / ModelState)
        try {
          final dynamic errorResponse = json.decode(response.body);
          String? parsed;
          if (errorResponse is Map<String, dynamic>) {
            // message field
            if (errorResponse['message'] is String) {
              parsed = errorResponse['message'] as String;
            }
            // errors map
            if (parsed == null && errorResponse['errors'] is Map) {
              final errorsMap = Map<String, dynamic>.from(errorResponse['errors'] as Map);
              final messages = <String>[];
              errorsMap.forEach((key, value) {
                if (value is List) {
                  messages.addAll(value.map((e) => e.toString()));
                } else if (value is String) {
                  messages.add(value);
                }
              });
              if (messages.isNotEmpty) {
                parsed = messages.join('\n');
              }
            }
            // title/detail fallback
            if (parsed == null && errorResponse['detail'] is String) {
              parsed = errorResponse['detail'] as String;
            }
            if (parsed == null && errorResponse['title'] is String) {
              parsed = errorResponse['title'] as String;
            }
          }
          errorMessage = parsed ?? "Greška prilikom registracije";
        } catch (e) {
          errorMessage = "Greška prilikom registracije";
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