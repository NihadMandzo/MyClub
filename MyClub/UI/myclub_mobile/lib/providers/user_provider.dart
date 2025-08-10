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
}
