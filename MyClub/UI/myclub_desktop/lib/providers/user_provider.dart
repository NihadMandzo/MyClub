import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/user.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super('User');

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

  Future<User?> getCurrentUser() async {
    if (authProvider?.userId != null) {
      return getUserById(authProvider!.userId!);
    }
    return null;
  }
}
