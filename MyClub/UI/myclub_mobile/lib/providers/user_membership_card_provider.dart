import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/requests/membership_purchase_request.dart';
import 'package:myclub_mobile/models/responses/payment_response.dart';
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

    /// Purchase membership card
  Future<PaymentResponse> purchaseMembership(MembershipPurchaseRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/purchase";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request.toJson());
    print("API POST Purchase Membership Request URL: $url");
    print("API POST Purchase Membership Request Body: $jsonRequest");
    print("API POST Purchase Membership Request Headers: $headers");

    var response = await http.post(uri, headers: headers, body: jsonRequest);
    print("API POST Purchase Membership Response Status: ${response.statusCode}");
    print("API POST Purchase Membership Response Body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } else {
      throw Exception("${response.statusCode}: ${response.body}");
    }
  }

  /// Confirm membership purchase
  Future<UserMembershipCardResponse> confirmMembershipPurchase(String transactionId) async {
    var url = "${BaseProvider.baseUrl}$endpoint/confirm";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    // Send the transactionId as a plain string in the request body
    // The backend expects [FromBody] string transactionId, so we need to send it as JSON string
    var requestBody = jsonEncode(transactionId);

    print("API POST Confirm Membership Purchase Request URL: $url");
    print("API POST Confirm Membership Purchase Request Headers: $headers");
    print("API POST Confirm Membership Purchase Request Body: $requestBody");

    var response = await http.post(uri, headers: headers, body: requestBody);
    print("API POST Confirm Membership Purchase Response Status: ${response.statusCode}");
    print("API POST Confirm Membership Purchase Response Body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return UserMembershipCardResponse.fromJson(data);
    } else {
      throw Exception("${response.statusCode}: ${response.body}");
    }
  }
}
