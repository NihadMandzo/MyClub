import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/order.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class OrderProvider extends BaseProvider<Order> {
  OrderProvider() : super("Order");

  @override
  Order fromJson(data) {
    return Order.fromJson(data);
  }
  
  /// Updates the status of an order
  /// 
  /// [orderId] - The ID of the order to update
  /// [newStatus] - The new status for the order
  Future<void> updateOrderStatus({
    required int orderId,
    required String newStatus,
  }) async {
    try {
      final url = "${BaseProvider.baseUrl}$endpoint/$orderId/status";
      final uri = Uri.parse(url);
      
      final response = await http.put(
        uri,
        headers: createHeaders(),
        body: jsonEncode({
          'NewStatus': newStatus,
        }),
      );
      
      if (!isValidResponse(response)) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      rethrow;
    }
  }
}
