import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/responses/user.dart';
import 'package:myclub_mobile/providers/base_provider.dart';
import 'package:myclub_mobile/providers/auth_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super('Users');

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<User?> getUserById(int id) async {
    try {
      var url = "${BaseProvider.baseUrl}$endpoint/$id";
      var uri = Uri.parse(url);
      var headers = createHeaders();

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);
        return fromJson(data);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  /// Get current user information using the /me endpoint
  Future<User?> getCurrentUser() async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/me";
      var uri = Uri.parse(url);
      
      // Get headers with auth token
      var headers = createHeaders();
      
      print("API GET Current User Request Headers: $headers");
      print("API GET Current User Request URL: $url");
      
      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);
        return fromJson(data);
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
    return null;
  }

  /// Legacy method - now uses getCurrentUser()
  Future<User?> getCurrentUserLegacy() async {
    // Try to get auth provider (local or global)
    AuthProvider? auth = authProvider ?? BaseProvider.getGlobalAuthProvider();
    
    if (auth?.userId != null) {
      return getUserById(auth!.userId!);
    }
    return null;
  }

  /// Check if current user has active membership
  Future<bool> hasActiveUserMembership() async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/has-active-membership";
      var uri = Uri.parse(url);
      
      // Get headers with auth token
      var headers = createHeaders();
      
      print("API GET Has Active Membership Request Headers: $headers");
      print("API GET Has Active Membership Request URL: $url");
      
      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);
        // The response should be a simple boolean value
        return data == true || data == 'true';
      }
    } catch (e) {
      print('Error checking active membership: $e');
    }
    return false; // Default to no discount if there's an error
  }

  /// Update current user profile using the /me/update endpoint
  Future<User> updateProfile(User user) async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/update-profile";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      
      // Create a request payload without sensitive fields like token
      var updatePayload = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'username': user.username,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
      };
      
      var jsonRequest = jsonEncode(updatePayload);
      
      print("API PUT Update Profile Request URL: $url");
      print("API PUT Update Profile Request Headers: $headers");
      print("API PUT Update Profile Request Body: $jsonRequest");

      var response = await http.put(uri, headers: headers, body: jsonRequest);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        throw Exception("Greška pri ažuriranju profila");
      }
    } catch (e) {
      throw Exception("Greška pri ažuriranju profila: $e");
    }
  }

  /// Deactivate current user account
  Future<void> deactivateAccount() async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/deactivate";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      
      print("API POST Deactivate User Request URL: $url");
      print("API POST Deactivate User Request Headers: $headers");

      var response = await http.post(uri, headers: headers);

      if (!isValidResponse(response)) {
        throw Exception("Greška pri deaktivaciji korisničkog naloga");
      }
    } catch (e) {
      throw Exception("Greška pri deaktivaciji korisničkog naloga: $e");
    }
  }

  
}
