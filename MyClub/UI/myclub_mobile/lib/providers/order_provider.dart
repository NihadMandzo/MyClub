import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/paged_result.dart';
import '../models/responses/order_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/order_insert_request.dart';
import '../models/requests/confirm_order_request.dart';
import 'base_provider.dart';

class OrderProvider extends BaseProvider<OrderResponse> {
  OrderProvider() : super("Order");

  @override
  OrderResponse fromJson(data) {
    return OrderResponse.fromJson(data);
  }

  /// Get user orders with authorization token
  Future<PagedResult<OrderResponse>> getUserOrders() async {
    var url = "${BaseProvider.baseUrl}$endpoint/user-orders";
    print("API GET Request URL: $url");
    print("API GET Request Headers: ${createHeaders()}");
    
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      
      return PagedResult<OrderResponse>.fromJson(
        data,
        (item) => fromJson(item),
      );
    } else {
      throw Exception("Greška tokom dohvatanja korisničkih narudžbi");
    }
  }

  /// Place a new order
  Future<PaymentResponse> placeOrder(OrderInsertRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/place-order";
    print("API POST Request URL: $url");
    print("API POST Request Headers: ${createHeaders()}");
    print("API POST Request Body: ${jsonEncode(request.toJson())}");
    
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var jsonRequest = jsonEncode(request.toJson());

    var response = await http.post(uri, headers: headers, body: jsonRequest);
    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return PaymentResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom naručivanja: ${response.body}");
    }
  }

  /// Confirm an order after payment
  Future<OrderResponse> confirmOrder(ConfirmOrderRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/confirm";
    print("API POST Request URL: $url");
    print("API POST Request Headers: ${createHeaders()}");
    print("API POST Request Body: ${jsonEncode(request.toJson())}");
    
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var jsonRequest = jsonEncode(request.toJson());

    var response = await http.post(uri, headers: headers, body: jsonRequest);
    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return OrderResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom potvrde narudžbe: ${response.body}");
    }
  }
}
