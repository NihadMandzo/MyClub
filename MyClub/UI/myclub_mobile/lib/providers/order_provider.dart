import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/paged_result.dart';
import '../models/responses/order_response.dart';
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
}
