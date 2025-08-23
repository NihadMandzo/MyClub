import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/requests/qr_validation_request.dart';
import 'package:myclub_mobile/models/requests/ticket_purchase_request.dart';
import 'package:myclub_mobile/models/responses/payment_response.dart';
import 'package:myclub_mobile/models/responses/qr_validation_response.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import '../models/responses/match_response.dart';
import '../models/responses/paged_result.dart';
import '../models/responses/user_ticket_response.dart';
import 'base_provider.dart';

class MatchProvider extends BaseProvider<MatchResponse> {
  MatchProvider() : super("Match");

  @override
  MatchResponse fromJson(data) {
    return MatchResponse.fromJson(data);
  }

Future<PagedResult<MatchResponse>> getPastMatches() async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/past";
      
      // Add query parameters to get all items
      var queryParams = {
        'retrieveAll': 'true',
      };
      
      var uri = Uri.parse(url).replace(queryParameters: queryParams);
      var headers = createHeaders();

      print("API GET Request URL: $uri");
      print("API GET Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);

        return PagedResult<MatchResponse>.fromJson(
          data,
          (item) => fromJson(item),
        );
      } else {
        throw Exception("Greška tokom dohvatanja podataka");
      }
    } catch (e) {
      throw Exception("Greška pri dohvatanju predstojećih utakmica: $e");
    }
  }

  /// Get upcoming matches (matches without results)
  Future<PagedResult<MatchResponse>> getUpcomingMatches() async {
   try {
      var url = "${BaseProvider.baseUrl}${endpoint}/upcoming";
      
      // Add query parameters to get all items
      var queryParams = {
        'retrieveAll': 'true',
      };
      
      var uri = Uri.parse(url).replace(queryParameters: queryParams);
      var headers = createHeaders();

      print("API GET Request URL: $uri");
      print("API GET Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);

        return PagedResult<MatchResponse>.fromJson(
          data,
          (item) => fromJson(item),
        );
      } else {
        throw Exception("Greška tokom dohvatanja podataka");
      }
    } catch (e) {
      throw Exception("Greška pri dohvatanju predstojećih utakmica: $e");
    }
  }

  /// Get all matches for a specific club
  Future<List<MatchResponse>> getMatchesForClub(int clubId) async {
    try {
      final searchObject = BaseSearchObject(
        retrieveAll: true,
      );
      final result = await get(searchObject: searchObject);
      return result.result ?? [];
    } catch (e) {
      throw Exception("Greška pri dohvatanju utakmica za klub: $e");
    }
  }

  /// Get user tickets
  /// [upcoming] - if true, returns only valid/upcoming tickets; if false, returns all tickets
  Future<List<UserTicketResponse>> getUserTickets({bool upcoming = false}) async {
    try {
      var url = "${BaseProvider.baseUrl}$endpoint/user-tickets";
      
      // Add query parameters
      var queryParams = {
        'upcoming': upcoming.toString(),
      };
      
      var uri = Uri.parse(url).replace(queryParameters: queryParams);
      var headers = createHeaders();

      print("API GET Request URL: $uri");
      print("API GET Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body) as List;
        return data.map((item) => UserTicketResponse.fromJson(item)).toList();
      } else {
        throw Exception("Greška tokom dohvatanja podataka");
      }
    } catch (e) {
      throw Exception("Greška pri dohvatanju korisničkih ulaznica: $e");
    }
  }

    /// Validate QR code ticket
  Future<QRValidationResponse> validateTicket(String qrCodeData) async {
    var url = "${BaseProvider.baseUrl}$endpoint/validate-ticket";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var request = QRValidationRequest(qrCodeData: qrCodeData);
    var jsonRequest = jsonEncode(request.toJson());

    print("Ticket validation URL: $url");
    print("Request body: $jsonRequest");

    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return QRValidationResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom validacije tiketa");
    }
  }

  /// Purchase ticket
  Future<PaymentResponse> purchaseTicket(TicketPurchaseRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/purchase-ticket";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request.toJson());
    print("API POST Purchase Ticket Request URL: $url");
    print("API POST Purchase Ticket Request Body: $jsonRequest");
    print("API POST Purchase Ticket Request Headers: $headers");

    var response = await http.post(uri, headers: headers, body: jsonRequest);
    print("API POST Purchase Ticket Response Status: ${response.statusCode}");
    print("API POST Purchase Ticket Response Body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } else {
      throw Exception("${response.statusCode}: ${response.body}");
    }
  }

  /// Confirm ticket purchase
  Future<void> confirmOrder(String transactionId) async {
    var url = "${BaseProvider.baseUrl}$endpoint/confirm";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var requestBody = jsonEncode(transactionId);

    print("API POST Confirm Ticket Purchase Request URL: $url");
    print("API POST Confirm Ticket Purchase Request Headers: $headers");

    var response = await http.post(uri, headers: headers, body: requestBody);
    print("API POST Confirm Ticket Purchase Response Status: ${response.statusCode}");
    print("API POST Confirm Ticket Purchase Response Body: ${response.body}");

    if (!isValidResponse(response)) {
      throw Exception("${response.statusCode}: ${response.body}");
    }
  }
}
