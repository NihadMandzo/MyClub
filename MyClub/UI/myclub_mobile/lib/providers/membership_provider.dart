import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/responses/membership_card.dart';
import 'package:myclub_mobile/providers/base_provider.dart';

class MembershipProvider extends BaseProvider<MembershipCard> {
  MembershipProvider() : super("MembershipCard");

  @override
  MembershipCard fromJson(data) {
    return MembershipCard.fromJson(data);
  }

  /// Get current membership card
  Future<MembershipCard?> getCurrentMembership() async {
    try {
      var url = "${BaseProvider.baseUrl}$endpoint/current";
      var uri = Uri.parse(url);
      var headers = createHeaders();

      print("API GET Current Membership Request URL: $url");
      print("API GET Current Membership Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);
        return MembershipCard.fromJson(data);
      } else {
        // If there's no current membership, return null instead of throwing
        if (response.statusCode == 404) {
          return null;
        }
        throw Exception("Greška tokom dohvatanja trenutnog članstva");
      }
    } catch (e) {
      print("Error getting current membership: $e");
      return null;
    }
  }
}
