import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/user_membership.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class UserMembershipProvider extends BaseProvider<UserMembership> {
  UserMembershipProvider() : super("UserMembership");

  @override
  UserMembership fromJson(data) {
    return UserMembership.fromJson(data as Map<String, dynamic>);
  }

  Future<void> markAsShipped(int id) async {
    final url = "${BaseProvider.baseUrl}$endpoint/$id/mark-shipped";
    final uri = Uri.parse(url);
    final headers = createHeaders();

    // Some APIs return body; we don't need it here but keep validation consistent
    final response = await http.post(uri, headers: headers, body: jsonEncode({}));

    if (!isValidResponse(response)) {
      throw Exception("Greška tokom označavanja kao poslano");
    }
  }
}
