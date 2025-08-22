import 'payment_request.dart';
import 'shipping_request.dart';
import 'order_item_insert_request.dart';

/// Order insert request model
class OrderInsertRequest extends PaymentRequest {
  final int userId;
  final ShippingRequest shipping;
  final String? notes;
  final List<OrderItemInsertRequest> items;

  OrderInsertRequest({
    required this.userId,
    required this.shipping,
    this.notes,
    required this.items,
    required String type,
    required double amount,
    String? paymentMethod,
  }) : super(
          type: type,
          amount: amount,
          paymentMethod: paymentMethod,
        );

  /// Convert to JSON for API requests
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'userId': userId,
      'shipping': shipping.toJson(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    });
    return json;
  }

  /// Create from JSON response
  factory OrderInsertRequest.fromJson(Map<String, dynamic> json) {
    return OrderInsertRequest(
      userId: json['userId'] ?? 0,
      shipping: ShippingRequest.fromJson(json['shipping'] ?? {}),
      notes: json['notes'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemInsertRequest.fromJson(item))
              .toList() ??
          [],
      type: json['type'] ?? 'Stripe',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }
}
