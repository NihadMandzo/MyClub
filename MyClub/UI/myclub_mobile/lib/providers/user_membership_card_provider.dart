import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/paged_result.dart';
import '../models/responses/user_membership_card_response.dart';
import 'base_provider.dart';

class UserMembershipCardProvider extends BaseProvider<UserMembershipCardResponse> {
  UserMembershipCardProvider() : super("UserMembership");

  @override
  UserMembershipCardResponse fromJson(data) {
    return UserMembershipCardResponse.fromJson(data);
  }

  /// Get user membership cards with authorization token
  Future<PagedResult<UserMembershipCardResponse>> getUserMembershipCards() async {
    var url = "${BaseProvider.baseUrl}$endpoint/user";
    print("API GET Request URL: $url");
    print("API GET Request Headers: ${createHeaders()}");
    
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      
      return PagedResult<UserMembershipCardResponse>.fromJson(
        data,
        (item) => fromJson(item),
      );
    } else {
      throw Exception("Greška tokom dohvatanja korisničkih članskih karata");
    }
  }
}
