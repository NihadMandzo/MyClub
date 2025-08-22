import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/requests/qr_validation_request.dart';
import 'package:myclub_mobile/models/responses/qr_validation_response.dart';
import '../providers/base_provider.dart';
import '../utility/api_config.dart';

class TicketValidationProvider extends BaseProvider<QRValidationResponse> {
  TicketValidationProvider() : super("ticket");

  @override
  QRValidationResponse fromJson(data) {
    return QRValidationResponse.fromJson(data);
  }

  /// Validate QR code ticket
  Future<QRValidationResponse> validateTicket(String qrCodeData) async {
    var url = "${ApiConfig.baseUrl}ticket/validate-ticket";
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
}
